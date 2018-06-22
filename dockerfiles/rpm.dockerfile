FROM centos:7
RUN yum groupinstall -y "Development Tools"

RUN yum install -y \
   btrfs-progs-devel \
   pkgconfig \
   tar \
   git \
   cmake \
   rpm-build \
   rpmdevtools \
   rpmbuildtools

# Install golang since the package managed one probably is too old and ppa's don't cover all distros
ARG GO_DL_URL
RUN curl -fsSL "${GO_DL_URL}" | tar xzC /usr/local
ENV GOPATH /go
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin

ARG VERSION
ENV VERSION ${VERSION}

ARG REF
ENV REF ${REF}

ENV DISTRO centos
ENV SUITE 7
RUN mkdir -p /go
ENV GOPATH /go
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin

COPY common/containerd.toml /root/rpmbuild/SOURCES/containerd.toml
COPY common/containerd.service /root/rpmbuild/SOURCES/containerd.service
COPY rpm/containerd.spec /root/rpmbuild/SPECS/containerd.spec
WORKDIR /root/rpmbuild
ENTRYPOINT ["/bin/rpmbuild"]
