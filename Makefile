#   Copyright 2018-2020 Docker Inc.

#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

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

RUN=docker run --security-opt seccomp=unconfined -e DEBIAN_FRONTEND=noninteractive --rm $(VOLUME_MOUNTS) -i $(ENV_VARS) $(BUILDER_IMAGE)
CHOWN=docker run --rm -v $(CURDIR):/v -w /v alpine chown
CHOWN_TO_USER=$(CHOWN) -R $(shell id -u):$(shell id -g)

all: build

.PHONY: clean
clean:
	-$(CHOWN_TO_USER) build/
	-$(RM) -r build/
	-$(RM) -r artifacts

.PHONY: build
build:
	$(BUILD)
	$(RUN)
	$(CHOWN_TO_USER) build/

.PHONY: validate
validate: ## Validate files license header
	docker run --rm -v $(CURDIR):/work -w /work $(GOLANG_IMAGE) bash -c 'go get -u github.com/kunalkushwaha/ltag && ./scripts/validate/fileheader'

