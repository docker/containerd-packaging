FROM centos:7

RUN yum groupinstall -y "Development Tools"

# Install git (git2u) through the IUS repository since it's more up to date
RUN yum remove -y git
RUN yum install -y https://centos7.iuscommunity.org/ius-release.rpm epel-release
RUN yum install -y \
   pkgconfig \
   tar \
   cmake \
   rpm-build \
   git2u

# Install golang since the package managed one probably is too old and ppa's don't cover all distros
ARG GO_DL_URL
RUN curl -fsSL "${GO_DL_URL}" | tar xzC /usr/local
ENV GOPATH /go
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin

COPY common/containerd.toml /root/rpmbuild/SOURCES/containerd.toml
COPY common/containerd.service /root/rpmbuild/SOURCES/containerd.service
COPY rpm/containerd.spec /root/rpmbuild/SPECS/containerd.spec
COPY scripts/build-rpm /build-rpm
COPY scripts/.rpm-helpers /.rpm-helpers

RUN mkdir -p /go
ARG REF
ENV GO_SRC_PATH /go/src/github.com/containerd/containerd
RUN git clone https://github.com/containerd/containerd.git ${GO_SRC_PATH}
RUN git -C ${GO_SRC_PATH} checkout ${REF}

WORKDIR /root/rpmbuild
ENTRYPOINT ["/build-rpm"]
