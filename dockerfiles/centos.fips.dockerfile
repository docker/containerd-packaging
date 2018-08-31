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

FROM dockereng/go-crypto-swap:centos-go1.10.3-92409f5
RUN yum install -y rpm-build git
ENV GOPATH /go
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin
ENV GO_SRC_PATH /go/src/github.com/containerd/containerd
COPY --from=containerd /containerd ${GO_SRC_PATH}
COPY --from=offline-install /offline-install /go/src/github.com/crosbymichael/offline-install
COPY common/ /root/rpmbuild/SOURCES/
COPY artifacts/runc.tar /root/rpmbuild/SOURCES/runc.tar
COPY rpm/containerd.spec /root/rpmbuild/SPECS/containerd.spec
COPY scripts/build-rpm /build-rpm
COPY scripts/.rpm-helpers /.rpm-helpers
WORKDIR /root/rpmbuild
# Overwrite repo that was failing on aarch64
RUN sed -i 's/altarch/centos/g' /etc/yum.repos.d/CentOS-Sources.repo
ENTRYPOINT ["/build-rpm"]
