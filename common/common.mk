GOARCH=$(shell docker run --rm golang go env GOARCH 2>/dev/null)
REF?=$(shell git ls-remote https://github.com/containerd/containerd.git | grep master | awk '{print $$1}')
RUNC_REF?=v1.0.0-rc9
GOVERSION?=1.12.10
GOLANG_IMAGE=docker.io/library/golang:$(GOVERSION)
BUILDER_IMAGE=containerd-builder-$@-$(GOARCH):$(shell git rev-parse --short HEAD)

ARCH:=$(shell uname -m)
PACKAGE?=containerd.io

BUILD_ARGS=--build-arg REF="$(REF)" \
	--build-arg GOLANG_IMAGE="$(GOLANG_IMAGE)" \
	--build-arg BUILD_IMAGE="$(BUILD_IMAGE)" \
	--build-arg BASE="$(BUILD_BASE)" \
	--build-arg RUNC_REF="$(RUNC_REF)"
