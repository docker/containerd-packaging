ARG BUILD_IMAGE=dockereng/sles:12.3
# Install golang since the package managed one probably is too old and ppa's don't cover all distros
ARG GOLANG_IMAGE
FROM ${GOLANG_IMAGE} as golang

FROM alpine:3.8 as containerd
RUN apk -u --no-cache add git
ARG REF
RUN git clone https://github.com/containerd/containerd.git /containerd
RUN git -C /containerd checkout ${REF}

FROM alpine:3.8 as runc
RUN apk -u --no-cache add git
ARG RUNC_REF
RUN git clone https://github.com/opencontainers/runc.git /runc
RUN git -C /runc checkout ${RUNC_REF}

FROM ${BUILD_IMAGE}
RUN zypper install -y rpm-build git
RUN zypper install -y \
    make \
    gcc \
    systemd \
    libbtrfs-devel \
    libseccomp-devel
ENV GOPATH /go
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin
ENV GO_SRC_PATH /go/src/github.com/containerd/containerd
COPY --from=golang /usr/local/go /usr/local/go/
# SLES doesn't have a go-md2man package because they're special
RUN go get github.com/cpuguy83/go-md2man
COPY --from=containerd /containerd ${GO_SRC_PATH}
COPY --from=runc /runc /go/src/github.com/opencontainers/runc
COPY common/ /root/rpmbuild/SOURCES/
COPY rpm/containerd.spec /root/rpmbuild/SPECS/containerd.spec
COPY scripts/build-rpm /build-rpm
COPY scripts/.rpm-helpers /.rpm-helpers
WORKDIR /root/rpmbuild
# suse puts the default build dir as /usr/src/rpmbuild
# to keep everything simple we just change the default
RUN echo "%_topdir    /root/rpmbuild" > /root/.rpmmacros

ARG PACKAGE
ENV PACKAGE=${PACKAGE:-containerd.io}
ENTRYPOINT ["/build-rpm"]
