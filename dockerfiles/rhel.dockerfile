ARG BUILD_IMAGE=dockereng/rhel-8:latest
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
RUN yum install -y rpm-build yum-utils git
ENV GOPATH /go
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin
ENV GO_SRC_PATH /go/src/github.com/containerd/containerd
ENV BUILDTAGS no_btrfs
COPY --from=golang /usr/local/go /usr/local/go/
RUN go get github.com/cpuguy83/go-md2man
COPY --from=containerd /containerd ${GO_SRC_PATH}
COPY --from=runc /runc /go/src/github.com/opencontainers/runc
COPY common/ /root/rpmbuild/SOURCES/
COPY rpm/containerd.spec /root/rpmbuild/SPECS/containerd.spec
COPY scripts/build-rpm /build-rpm
COPY scripts/.rpm-helpers /.rpm-helpers
WORKDIR /root/rpmbuild
ENTRYPOINT ["/build-rpm"]
