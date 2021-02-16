# syntax=docker/dockerfile:experimental


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
ARG GOLANG_IMAGE=golang:latest

# Install golang from the official image, since the package managed
# one probably is too old and ppa's don't cover all distros
FROM ${GOLANG_IMAGE} AS golang

FROM golang AS go-md2man
ARG GOPROXY=direct
ARG GO111MODULE=on
ARG MD2MAN_VERSION=v2.0.0
RUN go get github.com/cpuguy83/go-md2man/v2/@${MD2MAN_VERSION}

FROM ${BUILD_IMAGE} AS distro-image

FROM distro-image AS build-env
RUN mkdir -p /go
ENV GOPATH=/go
ENV PATH="${PATH}:/usr/local/go/bin:${GOPATH}/bin"
ENV IMPORT_PATH=github.com/containerd/containerd
ENV GO_SRC_PATH="/go/src/${IMPORT_PATH}"
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /root/containerd

# Install some pre-reqs
# NOTE: not using a cache-mount for apt, to prevent issues when building multiple
#       distros on the same machine / build-cache
RUN apt-get update -q && apt-get install -y --no-install-recommends \
    curl \
    devscripts \
    equivs \
    git \
    lsb-release \
 && apt-get clean \
 && rm -rf /var/cache/apt /var/lib/apt/lists/*

# Install build dependencies and build scripts
COPY --from=go-md2man /go/bin/go-md2man /go/bin/go-md2man
COPY debian/ debian/
# NOTE: not using a cache-mount for apt, to prevent issues when building multiple
#       distros on the same machine / build-cache
RUN apt-get update -q \
 && mk-build-deps -t "apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" -i debian/control \
 && apt-get clean \
 && rm -rf /var/cache/apt /var/lib/apt/lists/*
COPY scripts/build-deb    /root/
COPY scripts/.helpers     /root/

ARG PACKAGE
ENV PACKAGE=${PACKAGE:-containerd.io}

FROM build-env AS build-packages
RUN mkdir -p /archive /build
COPY common/containerd.service common/containerd.toml /root/common/
ARG CREATE_ARCHIVE
# NOTE: not using a cache-mount for /root/.cache/go-build, to prevent issues
#       with CGO when building multiple distros on the same machine / build-cache
RUN --mount=type=bind,from=golang,source=/usr/local/go/,target=/usr/local/go/ \
    --mount=type=bind,source=/src,target=/go/src,rw \
    /root/build-deb
ARG UID=0
ARG GID=0
RUN chown -R ${UID}:${GID} /archive /build

# Verify that installing the package succeeds succesfully, and if we're able
# to run both containerd and runc. This is just a rudimentary check to make
# sure that package dependencies are installed and that the binaries are not
# completely defunct.
FROM distro-image AS verify-packages
COPY --from=build-packages /build /build
# NOTE: not using a cache-mount for apt, to prevent issues when building multiple
#       distros on the same machine / build-cache
RUN apt-get update -q \
 && dpkg --force-depends -i $(find /build -mindepth 3 -type f -name containerd.io_*.deb) || true; \
    apt-get -y install --no-install-recommends --fix-broken \
 && apt-get clean \
 && rm -rf /var/cache/apt /var/lib/apt/lists/*
RUN containerd --version
RUN ctr --version
RUN runc --version

FROM scratch AS packages
COPY --from=build-packages  /archive /archive
COPY --from=verify-packages /build   /build

# This stage is mainly for debugging (running the build interactively with mounted source)
FROM build-env AS runtime
COPY --from=golang /usr/local/go/ /usr/local/go/
COPY common/containerd.service common/containerd.toml /root/common/
