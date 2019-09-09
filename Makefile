include common/common.mk

BUILD_IMAGE=centos:7
BUILD_TYPE=$(shell ./scripts/deb-or-rpm $(BUILD_IMAGE))
BUILD_BASE=$(shell ./scripts/determine-base $(BUILD_IMAGE))

ifeq ($(BUILD_BASE),)
$(error Invalid build image $(BUILD_IMAGE) no build base found)
endif

ifeq ($(BUILD_TYPE),)
$(error Invalid build image $(BUILD_IMAGE) no build type found)
endif

BUILD?=DOCKER_BUILDKIT=1 docker build \
	$(BUILD_ARGS) \
	-f dockerfiles/$(BUILD_TYPE).dockerfile \
	-t $(BUILDER_IMAGE) .

VOLUME_MOUNTS=-v "$(CURDIR)/build/:/out"

ifdef CONTAINERD_DIR
	VOLUME_MOUNTS+=-v "$(shell realpath $(CONTAINERD_DIR)):/go/src/github.com/containerd/containerd"
endif

ifdef RUNC_DIR
	VOLUME_MOUNTS+=-v "$(shell realpath $(RUNC_DIR)):/go/src/github.com/opencontainers/runc"
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
