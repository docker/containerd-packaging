FROM ubuntu:bionic

# Install some pre-reqs
RUN apt-get update && apt-get install -y curl devscripts equivs

# Install golang since the package managed one probably is too old and ppa's don't cover all distros
ARG GO_DL_URL
RUN curl -fsSL "${GO_DL_URL}" | tar xzC /usr/local
ENV GOPATH /go
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin

ENV IMPORT_PATH github.com/containerd/containerd
ENV GO_SRC_PATH /go/src/${IMPORT_PATH}

# Clone our source down from github
ARG VERSION
RUN mkdir -p ${GO_SRC_PATH}
RUN curl -fsSL https://${IMPORT_PATH}/archive/v${VERSION}.tar.gz | tar xvz -C ${GO_SRC_PATH} --strip-components=1

# Set up debian packaging files
RUN mkdir -p /root/containerd
COPY debian/ /root/containerd/debian
COPY common/ /root/common
WORKDIR /root/containerd

# Install all of our build dependencies, if any
RUN mk-build-deps -t "apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" -i debian/control
ARG REF
ENV LDFLAGS "-X ${IMPORT_PATH}/version.Package=${IMPORT_PATH} -X ${IMPORT_PATH}/version.VERSION=v${VERSION} -X ${IMPORT_PATH}/version.Revision=${REF}"

# Copy over our entrypoint
COPY scripts/build-deb /build-deb

ENTRYPOINT ["/build-deb"]
