FROM ubuntu:xenial

# Install some pre-reqs
RUN apt-get update && apt-get install -y curl devscripts equivs git

# Install golang since the package managed one probably is too old and ppa's don't cover all distros
ARG GOVERSION
ARG GOARCH
RUN curl -fsSL "https://golang.org/dl/go${GOVERSION}.linux-${GOARCH}.tar.gz" | tar xzC /usr/local
ENV GOPATH /go
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin
# needed for man pages
RUN go get -u github.com/cpuguy83/go-md2man

ENV IMPORT_PATH github.com/containerd/containerd
ENV GO_SRC_PATH /go/src/${IMPORT_PATH}

# Clone our source down from github
ARG TAG
RUN mkdir -p ${GO_SRC_PATH}
RUN curl -fsSL https://${IMPORT_PATH}/archive/${TAG}.tar.gz | tar xvz -C ${GO_SRC_PATH} --strip-components=1

# Set up debian packaging files
RUN mkdir -p /root/containerd
COPY debian/ /root/containerd/debian
COPY common/ /root/common
WORKDIR /root/containerd

# Install all of our build dependencies, if any
RUN mk-build-deps -t "apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" -i debian/control
ARG REF
ENV LDFLAGS "-X ${IMPORT_PATH}/version.Package=${IMPORT_PATH} -X ${IMPORT_PATH}/version.VERSION=${TAG} -X ${IMPORT_PATH}/version.Revision=${REF}"

# Copy over our entrypoint
COPY scripts/build-deb /build-deb

ENTRYPOINT ["/build-deb"]
