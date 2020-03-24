#   Copyright 2018-2020 Docker Inc.

#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

ARG BUILD_IMAGE=ubuntu:bionic
# Install golang since the package managed one probably is too old and ppa's don't cover all distros
ARG GOLANG_IMAGE

FROM ${GOLANG_IMAGE} AS golang

FROM alpine:3.10 AS git
RUN apk -u --no-cache add git

FROM git AS containerd-src
ARG REF=master
RUN git clone https://github.com/containerd/containerd.git /containerd
RUN git -C /containerd checkout "${REF}"

FROM git AS runc-src
ARG RUNC_REF=master
RUN git clone https://github.com/opencontainers/runc.git /runc
RUN git -C /runc checkout "${RUNC_REF}"

FROM golang AS go-md2man
ARG GOPROXY=direct
ARG GO111MODULE=on
ARG MD2MAN_VERSION=v2.0.0
RUN go get github.com/cpuguy83/go-md2man/v2/@${MD2MAN_VERSION}

FROM ${BUILD_IMAGE}
RUN cat /etc/os-release
ARG DEBIAN_FRONTEND=noninteractive

# Install some pre-reqs
RUN apt-get update && apt-get install -y --no-install-recommends curl devscripts equivs git lsb-release

RUN mkdir -p /go
ENV GOPATH=/go
ENV PATH="${PATH}:/usr/local/go/bin:${GOPATH}/bin"
ENV IMPORT_PATH=github.com/containerd/containerd
ENV GO_SRC_PATH="/go/src/${IMPORT_PATH}"

# Set up debian packaging files
COPY common/ /root/common/
COPY debian/ /root/containerd/debian/
WORKDIR /root/containerd

# Install all of our build dependencies, if any
RUN mk-build-deps -t "apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" -i debian/control

# Copy over our entrypoint
COPY scripts/build-deb /build-deb
COPY scripts/.helpers /.helpers

COPY --from=go-md2man      /go/bin/go-md2man /go/bin/go-md2man
COPY --from=golang         /usr/local/go/    /usr/local/go/
COPY --from=containerd-src /containerd/      /go/src/github.com/containerd/containerd/
COPY --from=runc-src       /runc/            /go/src/github.com/opencontainers/runc/

ARG PACKAGE
ENV PACKAGE=${PACKAGE:-containerd.io}
ENTRYPOINT ["/build-deb"]
