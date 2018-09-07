ARG BUILD_IMAGE=centos:7
# Install golang since the package managed one probably is too old and ppa's don't cover all distros
ARG GOLANG_IMAGE
FROM ${GOLANG_IMAGE} as golang

FROM alpine:3.8 as containerd
RUN apk -u --no-cache add git
ARG REF
RUN git clone https://github.com/containerd/containerd.git /containerd
RUN git -C /containerd checkout ${REF}

FROM ${BUILD_IMAGE}
RUN yum install -y rpm-build git
ENV GOPATH /go
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin
ENV GO_SRC_PATH /go/src/github.com/containerd/containerd
COPY --from=golang /usr/local/go /usr/local/go/
COPY --from=containerd /containerd ${GO_SRC_PATH}
COPY common/ /root/rpmbuild/SOURCES/
COPY artifacts/runc.tar /root/rpmbuild/SOURCES/runc.tar
COPY rpm/containerd.spec /root/rpmbuild/SPECS/containerd.spec
COPY scripts/build-rpm /build-rpm
COPY scripts/.rpm-helpers /.rpm-helpers
WORKDIR /root/rpmbuild
# Overwrite repo that was failing on aarch64
RUN sed -i 's/altarch/centos/g' /etc/yum.repos.d/CentOS-Sources.repo
ENTRYPOINT ["/build-rpm"]
