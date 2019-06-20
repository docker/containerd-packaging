GOARCH=$(shell docker run --rm golang go env GOARCH 2>/dev/null)
REF?=master
RUNC_REF?=96ec2177ae841256168fcf76954f7177af9446eb
GOVERSION?=1.10.6
GOLANG_IMAGE=docker.io/library/golang:$(GOVERSION)

BUILD_IMAGE=centos:7
BUILD_TYPE=$(shell ./scripts/deb-or-rpm $(BUILD_IMAGE))
BUILD_BASE=$(shell ./scripts/determine-base $(BUILD_IMAGE))
BUILD_ARGS=--build-arg REF="$(REF)" \
	--build-arg GOLANG_IMAGE="$(GOLANG_IMAGE)" \
	--build-arg BUILD_IMAGE="$(BUILD_IMAGE)" \
	--build-arg BASE="$(BUILD_BASE)" \
	--build-arg RUNC_REF="$(RUNC_REF)"


ifeq ($(BUILD_BASE),)
$(error Invalid build image $(BUILD_IMAGE) no build base found)
endif

ifeq ($(BUILD_TYPE),)
$(error Invalid build image $(BUILD_IMAGE) no build type found)
endif

BUILDER_IMAGE=dockereng/containerd-builder-$(BUILD_TYPE)-$(GOARCH):$(shell git rev-parse HEAD)
BUILD?=DOCKER_BUILDKIT=1 docker build \
	$(BUILD_ARGS) \
	-f dockerfiles/$(BUILD_TYPE).dockerfile \
	-t $(BUILDER_IMAGE) .

VOLUME_MOUNTS=-v "$(CURDIR)/build/:/out"

ifdef CONTAINERD_DIR
	VOLUME_MOUNTS+=-v "$(shell readlink -e $(CONTAINERD_DIR)):/go/src/github.com/containerd/containerd"
endif

ifdef RUNC_DIR
	VOLUME_MOUNTS+=-v "$(shell readlink -e $(RUNC_DIR)):/go/src/github.com/opencontainers/runc"
endif

ENV_VARS=
ifdef CREATE_ARCHIVE
	ENV_VARS+=-e CREATE_ARCHIVE=1
	VOLUME_MOUNTS+= -v "$(CURDIR)/archive:/archive"
endif

RUN=docker run --rm $(VOLUME_MOUNTS) -i $(ENV_VARS) $(BUILDER_IMAGE)
CHOWN=docker run --rm -v $(CURDIR):/v -w /v alpine chown
CHOWN_TO_USER=$(CHOWN) -R $(shell id -u):$(shell id -g)

all: build

.PHONY: clean
clean:
	-$(CHOWN_TO_USER) build/
	-$(RM) -r build/
	-$(RM) -r artifacts
	-$(RM) -r $(CONTAINERD_DIR)

.PHONY: build
build:
	$(BUILD)
	$(RUN)
	$(CHOWN_TO_USER) build/
