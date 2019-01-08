ARG BUILD_IMAGE=ubuntu:bionic
# Install golang since the package managed one probably is too old and ppa's don't cover all distros
ARG GOLANG_IMAGE
FROM ${GOLANG_IMAGE} as golang

FROM ${BUILD_IMAGE}
RUN cat /etc/os-release
# Install some pre-reqs
RUN apt-get update && apt-get install -y curl devscripts equivs git lsb-release
ENV GOPATH /go
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin
ENV IMPORT_PATH github.com/containerd/containerd
ENV GO_SRC_PATH /go/src/${IMPORT_PATH}

# Clone source down from github to provide a default build for containerd
# Override the containerd build repo by mounting a local containerd repo to /go/src/github.com/containerd/containerd
ARG REF=master
RUN mkdir -p ${GO_SRC_PATH}
RUN git clone https://${IMPORT_PATH} ${GO_SRC_PATH}
RUN git -C ${GO_SRC_PATH} checkout ${REF}

ARG RUNC_REF=master
RUN mkdir -p /go/src/github.com/opencontainers/runc
RUN git clone https://github.com/opencontainers/runc.git /go/src/github.com/opencontainers/runc
RUN git -C /go/src/github.com/opencontainers/runc checkout ${RUNC_REF}

# Set up debian packaging files
RUN mkdir -p /root/containerd
COPY debian/ /root/containerd/debian
COPY common /root/common
WORKDIR /root/containerd

COPY --from=golang /usr/local/go /usr/local/go/

# Install all of our build dependencies, if any
RUN mk-build-deps -t "apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" -i debian/control

# Copy over our entrypoint
COPY scripts/build-deb /build-deb
COPY scripts/.helpers /.helpers

ARG PACKAGE
ENV PACKAGE=${PACKAGE:-containerd.io}
ENTRYPOINT ["/build-deb"]
