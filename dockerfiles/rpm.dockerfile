# syntax=docker/dockerfile:1


#   Copyright 2018-2022 Docker Inc.

#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

ARG BUILD_IMAGE=quay.io/centos/centos:stream9
ARG BASE=centos
ARG GOLANG_IMAGE=golang:latest

# Install golang from the official image, since the package managed
# one probably is too old and ppa's don't cover all distros
FROM ${GOLANG_IMAGE} AS golang

FROM golang AS go-md2man
ARG GOPROXY=direct
ARG MD2MAN_VERSION=v2.0.5
RUN go install github.com/cpuguy83/go-md2man/v2@${MD2MAN_VERSION}

FROM ${BUILD_IMAGE} AS redhat-base
RUN dnf install -y rpm-build git dnf-plugins-core

FROM redhat-base AS rhel-base
RUN --mount=type=secret,id=rh-user --mount=type=secret,id=rh-pass <<-EOT
	rm -f /etc/rhsm-host

	if [ ! -f /run/secrets/rh-user ] || [ ! -f /run/secrets/rh-pass ]; then
		echo "Either RH_USER or RH_PASS is not set. Running build without subscription."
	else
		subscription-manager register \
			--username="$(cat /run/secrets/rh-user)" \
			--password="$(cat /run/secrets/rh-pass)"

		subscription-manager repos --enable codeready-builder-for-rhel-$(source /etc/os-release && echo "${VERSION_ID%.*}"-$(arch)-rpms)
	fi
EOT

FROM redhat-base AS centos-base
RUN dnf config-manager --set-enabled crb

FROM redhat-base AS ol-base
RUN dnf config-manager --set-enabled ol8_addons

FROM redhat-base AS rocky-base

FROM redhat-base AS almalinux-base

FROM redhat-base AS fedora-base
# FIXME(thaJeztah): workaround for building on Fedora 41 on arm64
#
# go1.21 and up have a patch that enforces the use of ld.gold to work around
# a bug in GNU binutils. See;
# - https://github.com/golang/go/issues/22040.
# - https://github.com/golang/go/commit/cd77738198ffe0c4a1db58352c89f9b2d2a4e85e
#
# Fedora 41 and up has a fixed version of binutils, and no longer requires that
# patch, but will fail without ld.gold installed;
#
#   /usr/bin/gcc -Wl,-z,now -Wl,-z,nocopyreloc -fuse-ld=gold -o $WORK/b001/exe/a.out -rdynamic /tmp/go-link-1738353519/go.o /tmp/go-link-1738353519/000000.o /tmp/go-link-1738353519/000001.o /tmp/go-link-1738353519/000002.o /tmp/go-link-1738353519/000003.o /tmp/go-link-1738353519/000004.o /tmp/go-link-1738353519/000005.o /tmp/go-link-1738353519/000006.o /tmp/go-link-1738353519/000007.o /tmp/go-link-1738353519/000008.o /tmp/go-link-1738353519/000009.o /tmp/go-link-1738353519/000010.o /tmp/go-link-1738353519/000011.o /tmp/go-link-1738353519/000012.o /tmp/go-link-1738353519/000013.o /tmp/go-link-1738353519/000014.o /tmp/go-link-1738353519/000015.o /tmp/go-link-1738353519/000016.o /tmp/go-link-1738353519/000017.o /tmp/go-link-1738353519/000018.o /tmp/go-link-1738353519/000019.o /tmp/go-link-1738353519/000020.o /tmp/go-link-1738353519/000021.o /tmp/go-link-1738353519/000022.o /tmp/go-link-1738353519/000023.o /tmp/go-link-1738353519/000024.o -O2 -g -lresolv -O2 -g -lpthread -O2 -g -ldl -O2 -g
#   collect2: fatal error: cannot find 'ld'
#
# Fedora's build of Go carries a patch for that, but it's not (yet) in upstream;
# - https://src.fedoraproject.org/rpms/golang/blob/a867bd88a656c1d6e91e7b18bab696dc3fcf1e77/f/0006-Default-to-ld.bfd-on-ARM64.patch
# - https://src.fedoraproject.org/rpms/golang/c/a867bd88a656c1d6e91e7b18bab696dc3fcf1e77?branch=rawhide
#
# As a workaround; install binutils-gold
RUN if [ "$(arch)" = 'aarch64' ] && [ $(source /etc/os-release && echo "${VERSION_ID%.*}") -ge 41 ]; then dnf -y install binutils-gold; fi

FROM ${BUILD_IMAGE} AS amzn-base
RUN yum install -y yum-utils rpm-build git

FROM ${BUILD_IMAGE} AS suse-base
RUN zypper -n install rpm-build git

# Align the rpm directories used with other rpm-distros.
#
# CentOS, RHEL, and Fedora all use "~/rpmbuild" ("/root/rpmbuild") as default,
# but SUSE uses "/usr/src/packages". Align the directory so that we can keep
# our scripts universal.
RUN echo "%_topdir    /root/rpmbuild" > /root/.rpmmacros

FROM ${BASE}-base AS distro-image

FROM distro-image AS build-env
RUN mkdir -p /go
ENV GOPATH=/go
ENV GOTOOLCHAIN=local
ENV PATH="${PATH}:/usr/local/go/bin:${GOPATH}/bin"
ENV IMPORT_PATH=github.com/containerd/containerd
ENV GO_SRC_PATH="/go/src/${IMPORT_PATH}"
ENV CC=gcc
WORKDIR /root/rpmbuild

# Install build dependencies and build scripts
COPY --link --from=go-md2man /go/bin/go-md2man /go/bin/go-md2man
COPY --link rpm/containerd.spec SPECS/containerd.spec
COPY --link scripts/build-rpm    /root/
COPY --link scripts/.rpm-helpers /root/
RUN . /root/.rpm-helpers; install_build_deps SPECS/containerd.spec

ARG PACKAGE
ENV PACKAGE=${PACKAGE:-containerd.io}

FROM build-env AS build-packages
RUN mkdir -p /archive /build
COPY common/containerd.service common/containerd.toml SOURCES/
ARG CREATE_ARCHIVE
# NOTE: not using a cache-mount for /root/.cache/go-build, to prevent issues
#       with CGO when building multiple distros on the same machine / build-cache
RUN --mount=type=bind,from=golang,source=/usr/local/go/,target=/usr/local/go/ \
    --mount=type=bind,source=/src,target=/go/src,rw \
    --mount=type=bind,source=/src/github.com/containerd/containerd,target=/root/rpmbuild/SOURCES/containerd \
    --mount=type=bind,source=/src/github.com/opencontainers/runc,target=/root/rpmbuild/SOURCES/runc \
    /root/build-rpm
ARG UID=0
ARG GID=0
RUN chown -R ${UID}:${GID} /archive /build

# Verify that installing the package succeeds succesfully, and if we're able
# to run both containerd and runc. This is just a rudimentary check to make
# sure that package dependencies are installed and that the binaries are not
# completely defunct.
#
# For rpms, installing packages with 'rpm -ivh my-local-package.rpm' or
# 'yum --nogpgcheck localinstall packagename.arch.rpm' does not perform
# dependency resolution, so we need to setup a local repository to verify the
# installation (including dependencies).
#
# NOTE: Installation of source-packages is not currently tested here.
FROM distro-image AS verify-packages
COPY scripts/.rpm-helpers /root/
# On OpenSUSE/SLES, the package is now named `createrepo_c`
RUN . /root/.rpm-helpers; if [ -d "/etc/zypp/repos.d/" ]; then install_package createrepo_c; else install_package createrepo; fi
RUN if [ -d "/etc/zypp/repos.d/" ]; then ln -s "/etc/zypp/repos.d" "/etc/yum.repos.d"; fi \
 && echo -e "[local]\nname=Test Repo\nbaseurl=file:///build/\nenabled=1\ngpgcheck=0" >  "/etc/yum.repos.d/local.repo"
COPY --from=build-packages /build/. /build/
RUN createrepo /build \
 && . /root/.rpm-helpers \
 && install_package containerd.io \
 && rm -rf /build/repodata
RUN containerd --version
RUN ctr --version
RUN runc --version

FROM scratch AS packages
COPY --link --from=build-packages  /archive /archive
COPY --link --from=verify-packages /build   /build

# This stage is mainly for debugging (running the build interactively with mounted source)
FROM build-env AS runtime
ENV GOTOOLCHAIN=local
COPY --link --from=golang /usr/local/go/ /usr/local/go/
COPY --link common/containerd.service common/containerd.toml SOURCES/
