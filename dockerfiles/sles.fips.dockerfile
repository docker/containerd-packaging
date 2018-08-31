FROM alpine:3.8 as containerd
RUN apk -u --no-cache add git
ARG REF
RUN git clone https://github.com/containerd/containerd.git /containerd
RUN git -C /containerd checkout ${REF}

FROM alpine:3.8 as offline-install
RUN apk -u --no-cache add git
ARG OFFLINE_INSTALL_REF
RUN git clone https://github.com/crosbymichael/offline-install.git /offline-install
RUN git -C /offline-install checkout ${OFFLINE_INSTALL_REF}

FROM dockereng/go-crypto-swap:sles-go1.10.4-92409f5
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
# SLES doesn't have a go-md2man package because they're special
RUN go get github.com/cpuguy83/go-md2man
COPY --from=containerd /containerd ${GO_SRC_PATH}
COPY --from=offline-install /offline-install /go/src/github.com/crosbymichael/offline-install
COPY common/ /root/rpmbuild/SOURCES/
COPY artifacts/runc.tar /root/rpmbuild/SOURCES/runc.tar
COPY rpm/containerd.spec /root/rpmbuild/SPECS/containerd.spec
COPY scripts/build-rpm /build-rpm
COPY scripts/.rpm-helpers /.rpm-helpers
WORKDIR /root/rpmbuild
# suse puts the default build dir as /usr/src/rpmbuild
# to keep everything simple we just change the default
RUN echo "%_topdir    /root/rpmbuild" > /root/.rpmmacros
ENTRYPOINT ["/build-rpm"]
