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

ENV DISTRO centos
ENV SUITE 7
RUN mkdir -p /go
ENV GOPATH /go
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin

COPY common/containerd.toml /root/rpmbuild/SOURCES/containerd.toml
COPY common/containerd.service /root/rpmbuild/SOURCES/containerd.service
COPY rpm/centos/containerd.spec /root/rpmbuild/SPECS/containerd.spec
WORKDIR /root/rpmbuild
ENTRYPOINT ["/bin/rpmbuild"]
