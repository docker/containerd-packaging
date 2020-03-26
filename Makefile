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

# The PROGRESS variable allows overriding the docker build --progress option.
# For example, use "make PROGRESS=plain ..." to show build progress in plain test
PROGRESS=auto
VOLUME_MOUNTS=-v "$(CURDIR)/build/:/build"

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

CHOWN=docker run --rm -v $(CURDIR):/v -w /v alpine chown
CHOWN_TO_USER=$(CHOWN) -R $(shell id -u):$(shell id -g)

all: build

.PHONY: clean
clean:
	-$(CHOWN_TO_USER) build/
	-$(RM) -r build/
	-$(RM) -r artifacts
	-$(RM) -r src

src: src/github.com/opencontainers/runc src/github.com/containerd/containerd

ifdef RUNC_DIR
src/github.com/opencontainers/runc:
	cp -r "$(RUNC_DIR)" src/github.com/opencontainers/runc
else
src/github.com/opencontainers/runc:
	git clone https://github.com/opencontainers/runc.git $@
endif

ifdef CONTAINERD_DIR
src/github.com/containerd/containerd:
	cp -r "$(CONTAINERD_DIR)" $@
else
src/github.com/containerd/containerd:
	git clone https://github.com/containerd/containerd.git $@
endif

.PHONY: checkout
checkout: src
	@git -C src/github.com/opencontainers/runc   checkout -q "$(RUNC_REF)"
	@git -C src/github.com/containerd/containerd checkout -q "$(REF)"

.PHONY: build
build: checkout
build:
	@docker pull "$(BUILD_IMAGE)"

	@if [ -z "$(BUILD_BASE)" ]; then echo "Invalid build image $(BUILD_IMAGE) no build base found"; exit 1; fi
	@if [ -z "$(BUILD_TYPE)" ]; then echo "Invalid build image $(BUILD_IMAGE) no build type found"; exit 1; fi

	@set -x; DOCKER_BUILDKIT=1 docker build \
		--build-arg GOLANG_IMAGE="$(GOLANG_IMAGE)" \
		--build-arg BUILD_IMAGE="$(BUILD_IMAGE)" \
		--build-arg BASE="$(BUILD_BASE)" \
		--file="dockerfiles/$(BUILD_TYPE).dockerfile" \
		--progress="$(PROGRESS)" \
		--tag="$(BUILDER_IMAGE)" \
		.

	@set -x; docker run --rm $(VOLUME_MOUNTS) -i $(ENV_VARS) "$(BUILDER_IMAGE)"
	$(CHOWN_TO_USER) build/

.PHONY: validate
validate: ## Validate files license header
	docker run --rm -v $(CURDIR):/work -w /work $(GOLANG_IMAGE) bash -c 'go get -u github.com/kunalkushwaha/ltag && ./scripts/validate/fileheader'
