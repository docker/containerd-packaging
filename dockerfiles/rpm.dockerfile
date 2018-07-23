# Install golang since the package managed one probably is too old and ppa's don't cover all distros
FROM alpine:latest as golang
RUN apk add curl
ARG GO_DL_URL
RUN curl -fsSL "${GO_DL_URL}" | tar xzC /usr/local

FROM alpine:latest as containerd
RUN apk add git
ARG REF
RUN git clone https://github.com/containerd/containerd.git /containerd
RUN git -C /containerd checkout ${REF}

FROM centos:7
# Install git (git2u) through the IUS repository since it's more up to date
RUN yum install -y https://centos7.iuscommunity.org/ius-release.rpm epel-release
RUN yum install -y rpm-build git2u
ARG REF
ENV GOPATH /go
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin
ENV GO_SRC_PATH /go/src/github.com/containerd/containerd
COPY --from=golang /usr/local/go /usr/local/go/
COPY --from=containerd /containerd ${GO_SRC_PATH}
COPY common/containerd.toml /root/rpmbuild/SOURCES/containerd.toml
COPY common/containerd.service /root/rpmbuild/SOURCES/containerd.service
COPY rpm/containerd.spec /root/rpmbuild/SPECS/containerd.spec
COPY scripts/build-rpm /build-rpm
COPY scripts/.rpm-helpers /.rpm-helpers
WORKDIR /root/rpmbuild
ENTRYPOINT ["/build-rpm"]
