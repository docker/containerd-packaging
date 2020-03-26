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

ARG BUILD_IMAGE=centos:7
ARG BASE=centos
ARG GOLANG_IMAGE=golang:latest

# Install golang from the official image, since the package managed
# one probably is too old and ppa's don't cover all distros
FROM ${GOLANG_IMAGE} AS golang

FROM golang AS go-md2man
ARG GOPROXY=direct
ARG GO111MODULE=on
ARG MD2MAN_VERSION=v2.0.0
RUN go get github.com/cpuguy83/go-md2man/v2/@${MD2MAN_VERSION}

FROM ${BUILD_IMAGE} AS redhat-base
RUN yum install -y yum-utils rpm-build git

FROM redhat-base AS rhel-base

FROM redhat-base AS centos-base
RUN if [ -f /etc/yum.repos.d/CentOS-PowerTools.repo ]; then sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/CentOS-PowerTools.repo; fi
# In aarch64 (arm64) images, the altarch repo is specified as repository, but
# failing, so replace the URL.
RUN if [ -f /etc/yum.repos.d/CentOS-Sources.repo ]; then sed -i 's/altarch/centos/g' /etc/yum.repos.d/CentOS-Sources.repo; fi

FROM redhat-base AS amzn-base

FROM redhat-base AS ol-base
RUN . "/etc/os-release"; if [ "${VERSION_ID%.*}" -eq 7 ]; then yum-config-manager --enable ol7_addons --enable ol7_optional_latest; fi
RUN . "/etc/os-release"; if [ "${VERSION_ID%.*}" -eq 8 ]; then yum-config-manager --enable ol8_addons; fi

FROM ${BUILD_IMAGE} AS fedora-base
RUN dnf install -y rpm-build git dnf-plugins-core

FROM ${BUILD_IMAGE} AS suse-base
# On older versions of Docker the path may not be explicitly set
# opensuse also does not set a default path in their docker images
RUN zypper -n install rpm-build git
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH}
RUN echo "%_topdir    /root/rpmbuild" > /root/.rpmmacros

FROM ${BASE}-base AS distro-image

FROM distro-image AS build-env
RUN mkdir -p /go
ENV GOPATH=/go
ENV PATH="${PATH}:/usr/local/go/bin:${GOPATH}/bin"
ENV IMPORT_PATH=github.com/containerd/containerd
ENV GO_SRC_PATH="/go/src/${IMPORT_PATH}"
WORKDIR /root/rpmbuild

# Install build dependencies and build scripts
COPY --from=go-md2man /go/bin/go-md2man /go/bin/go-md2man
COPY --from=golang    /usr/local/go/    /usr/local/go/
COPY rpm/containerd.spec SPECS/containerd.spec
COPY scripts/build-rpm    /
COPY scripts/.rpm-helpers /

# Copy over the source code
COPY common/containerd.service common/containerd.toml SOURCES/
COPY src /go/src

ARG PACKAGE
ENV PACKAGE=${PACKAGE:-containerd.io}
ENTRYPOINT ["/build-rpm"]
