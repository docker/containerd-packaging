# Install golang since the package managed one probably is too old and ppa's don't cover all distros
ARG GOLANG_IMAGE
FROM ${GOLANG_IMAGE} as golang

FROM alpine:latest as containerd
RUN apk -u --no-cache add git
ARG REF
RUN git clone https://github.com/containerd/containerd.git /containerd
RUN git -C /containerd checkout ${REF}

FROM alpine:latest as offline-install
RUN apk -u --no-cache add git
ARG OFFLINE_INSTALL_REF
RUN git clone https://github.com/crosbymichael/offline-install.git /offline-install
RUN git -C /offline-install checkout ${OFFLINE_INSTALL_REF}

FROM clefos:7
RUN yum install -y rpm-build git yum-utils gcc
ENV GOPATH /go
ENV GO_SRC_PATH /go/src/github.com/containerd/containerd
COPY --from=golang /usr/local/go /usr/local/go/
COPY --from=containerd /containerd ${GO_SRC_PATH}
COPY --from=offline-install /offline-install /go/src/github.com/crosbymichael/offline-install
COPY common/ /root/rpmbuild/SOURCES/
COPY artifacts/runc.tar /root/rpmbuild/SOURCES/runc.tar
COPY rpm/containerd.spec /root/rpmbuild/SPECS/containerd.spec
COPY scripts/build-rpm /build-rpm
COPY scripts/.rpm-helpers /.rpm-helpers
WORKDIR /root/rpmbuild
# Need for build-rpm on s390x
RUN ln /usr/bin/gcc /usr/bin/s390x-linux-gnu-gcc
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin
ENTRYPOINT ["/build-rpm"]
