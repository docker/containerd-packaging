# Install golang since the package managed one probably is too old and ppa's don't cover all distros
FROM alpine:latest as golang
RUN apk add curl
ARG GO_DL_URL
RUN curl -fsSL "${GO_DL_URL}" | tar xzC /usr/local

FROM ubuntu:bionic

# Install some pre-reqs
RUN apt-get update && apt-get install -y curl devscripts equivs git

COPY --from=golang /usr/local/go /usr/local/go/
ENV GOPATH /go
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin

ENV IMPORT_PATH github.com/containerd/containerd
ENV GO_SRC_PATH /go/src/${IMPORT_PATH}

# Clone our source down from github
ARG REF
RUN mkdir -p ${GO_SRC_PATH}
RUN git clone https://${IMPORT_PATH}.git ${GO_SRC_PATH}
RUN git -C ${GO_SRC_PATH} checkout ${REF}

# Set up debian packaging files
RUN mkdir -p /root/containerd
COPY debian/ /root/containerd/debian
COPY common/ /root/common
WORKDIR /root/containerd

# Install all of our build dependencies, if any
RUN mk-build-deps -t "apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" -i debian/control

# Copy over our entrypoint
COPY scripts/build-deb /build-deb

ENTRYPOINT ["/build-deb"]
