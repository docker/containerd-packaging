ARG BUILD_IMAGE=ubuntu:bionic
# Install golang since the package managed one probably is too old and ppa's don't cover all distros
ARG GOLANG_IMAGE
FROM ${GOLANG_IMAGE} as golang

FROM alpine:3.8 as containerd
RUN apk -u --no-cache add git
ARG REF
ENV IMPORT_PATH github.com/containerd/containerd
RUN git clone https://${IMPORT_PATH}.git /containerd
RUN git -C /containerd checkout ${REF}

FROM alpine:3.8 as runc
RUN apk -u --no-cache add git
ARG RUNC_REF
RUN git clone https://github.com/opencontainers/runc.git /runc
RUN git -C /runc checkout ${RUNC_REF}

FROM ${BUILD_IMAGE}
RUN apt-get update && apt-get install -y curl devscripts equivs git
ENV GOPATH /go
ENV GO_SRC_PATH /go/src/github.com/containerd/containerd
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin
ARG REF
COPY --from=golang /usr/local/go /usr/local/go/
COPY --from=containerd /containerd ${GO_SRC_PATH}
COPY --from=runc /runc /go/src/github.com/opencontainers/runc

# Set up debian packaging files
RUN mkdir -p /root/containerd
COPY debian/ /root/containerd/debian
COPY common/ /root/common
WORKDIR /root/containerd

# Install all of our build dependencies, if any
RUN mk-build-deps -t "apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" -i debian/control

# Copy over our entrypoint
COPY scripts/build-deb /build-deb
COPY scripts/.helpers /.helpers

ARG PACKAGE
ENV PACKAGE=${PACKAGE:-containerd.io}
ENTRYPOINT ["/build-deb"]
