GOARCH=$(shell docker run --rm golang go env GOARCH 2>/dev/null)
REF?=$(shell git ls-remote https://github.com/containerd/containerd.git | grep master | awk '{print $$1}')
RUNC_REF?=425e105d5a03fabd737a126ad93d62a9eeede87f
GOVERSION?=1.11.12
GOLANG_IMAGE=docker.io/library/golang:$(GOVERSION)
BUILDER_IMAGE=containerd-builder-$@-$(GOARCH):$(shell git rev-parse --short HEAD)

CONTAINERD_REPO?=containerd/containerd
CONTAINERD_BRANCH?=release/1.2
CONTAINERD_DIR?=$(shell basename $(CONTAINERD_REPO))

ARCH:=$(shell uname -m)
PACKAGE?=containerd.io

BUILD_ARGS=--build-arg REF="$(REF)" \
	--build-arg GOLANG_IMAGE="$(GOLANG_IMAGE)" \
	--build-arg BUILD_IMAGE="$(BUILD_IMAGE)" \
	--build-arg BASE="$(BUILD_BASE)" \
	--build-arg RUNC_REF="$(RUNC_REF)"

$(CONTAINERD_DIR):
	git clone git@github.com:$(CONTAINERD_REPO)
	git -C $(CONTAINERD_DIR) checkout $(CONTAINERD_BRANCH)
