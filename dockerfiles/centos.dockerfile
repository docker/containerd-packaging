FROM centos:7
RUN yum groupinstall -y "Development Tools"
#RUN yum -y swap -- remove systemd-container systemd-container-libs -- install systemd systemd-libs
RUN yum install -y \
   glibc-static \
   btrfs-progs-devel \
   device-mapper-devel \
   libseccomp-devel \
   libselinux-devel \
   libtool-ltdl-devel \
   selinux-policy-devel \
   systemd-devel \
   pkgconfig \
   tar \
   git \
   cmake \
   rpm-build \
   rpmdevtools \
   rpmbuildtools \
   vim-common


#ENV GO_VERSION 1.9.5
ENV DISTRO centos
ENV SUITE 7
RUN mkdir -p /go
ENV GOPATH /go
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin

ENV IMPORT_PATH github.com/containerd/containerd
ENV TAR_PATH /root/rpmbuild/SOURCES/

# Clone source down from github
ARG TAG
RUN mkdir -p ${TAR_PATH}
RUN curl -fsSL https://${IMPORT_PATH}/archive/${TAG}.tar.gz > ${TAR_PATH}/containerd.tar.gz 

#ENV AUTO_GOPATH 1
COPY common/containerd.toml /root/rpmbuild/SOURCES/containerd.toml
COPY common/containerd.service /root/rpmbuild/SOURCES/containerd.service
COPY rpm/centos/containerd.spec /root/rpmbuild/SPECS/containerd.spec
WORKDIR /root/rpmbuild
ENTRYPOINT ["/bin/rpmbuild"]
