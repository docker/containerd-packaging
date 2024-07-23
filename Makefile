#   Copyright 2018-2022 Docker Inc.

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

ARCH=$(shell uname -m)
BUILD_IMAGE=ubuntu:focal
BUILD_TYPE=$(shell ./scripts/deb-or-rpm $(BUILD_IMAGE))
BUILD_BASE=$(shell ./scripts/determine-base $(BUILD_IMAGE))

# The PROGRESS variable allows overriding the docker build --progress option.
# For example, use "make PROGRESS=plain ..." to show build progress in plain test
PROGRESS=auto
TARGET=packages

all: build

.PHONY: clean
clean:
	-$(RM) -r archive
	-$(RM) -r artifacts
	-$(RM) -r build
	-$(RM) -r src
	-$(RM) common/containerd.service
	-docker builder prune -f --filter until=24h

.PHONY: src
src: src/github.com/containerd/containerd src/github.com/opencontainers/runc

common/containerd.service: checkout
	# upstream systemd unit uses /usr/local/bin, whereas our packages use /usr/bin
	sed 's#/usr/local/bin/containerd#/usr/bin/containerd#g' src/github.com/containerd/containerd/containerd.service > $@

ifdef RUNC_DIR
src/github.com/opencontainers/runc:
	mkdir -p "$(@D)"
	cp -r "$(RUNC_DIR)" $@
else
src/github.com/opencontainers/runc:
	git init $@
	git -C $@ remote add origin "$(RUNC_REMOTE)"
endif

ifdef CONTAINERD_DIR
src/github.com/containerd/containerd:
	mkdir -p "$(@D)"
	cp -r "$(CONTAINERD_DIR)" $@
else
src/github.com/containerd/containerd:
	git init $@
	git -C $@ remote add origin "$(CONTAINERD_REMOTE)"
endif

# This targets allows building multiple distros at once, for example:
#
#     make docker.io/library/ubuntu:jammy docker.io/library/centos:7
#     make quay.io/centos/centos:stream8
#
# It is a shorthand for "make BUILD_IMAGE=mydistro:version build"
.PHONY: docker.io/% quay.io/% registry.access.redhat.com/%
docker.io/% quay.io/% registry.access.redhat.com/%:
	$(MAKE) BUILD_IMAGE="$@" build

.PHONY: checkout
checkout: src
	./scripts/checkout.sh src/github.com/containerd/containerd "$(REF)"
	./scripts/checkout.sh src/github.com/opencontainers/runc "$$(./scripts/determine-runc-version)"

.PHONY: build
build: checkout common/containerd.service
build:
	@echo "--------------------------------------------------------------------"
	@echo "Building $(TARGET) on $(BUILD_IMAGE)"
	@echo ""
	@echo "containerd   : $(REF) (commit: $(shell git -C "src/github.com/containerd/containerd" log -1 --pretty='%h'))"
	@echo "runc         : $$(./scripts/determine-runc-version) (commit: $$(git -C "src/github.com/opencontainers/runc" log -1 --pretty='%h'))"
	@echo "architecture : $(ARCH)"
	@echo "build image  : $(BUILD_IMAGE)"
	@echo "golang image : $(GOLANG_IMAGE)"
	@echo "--------------------------------------------------------------------"

	@docker pull "$(BUILD_IMAGE)"

	@if [ -z "$(BUILD_BASE)" ]; then echo "Invalid build image $(BUILD_IMAGE) no build base found"; exit 1; fi
	@if [ -z "$(BUILD_TYPE)" ]; then echo "Invalid build image $(BUILD_IMAGE) no build type found"; exit 1; fi

	@set -x; DOCKER_BUILDKIT=1 docker build \
		--pull \
		--build-arg RH_USER=$(RH_USER) \
		--build-arg RH_PASS=$(RH_PASS) \
		--platform linux/$(ARCH) \
		--build-arg GOLANG_IMAGE="$(GOLANG_IMAGE)" \
		--build-arg BUILD_IMAGE="$(BUILD_IMAGE)" \
		--build-arg BASE="$(BUILD_BASE)" \
		--build-arg CREATE_ARCHIVE="$(CREATE_ARCHIVE)" \
		--build-arg UID="$(shell id -u)" \
		--build-arg GID="$(shell id -g)" \
		--file="dockerfiles/$(BUILD_TYPE).dockerfile" \
		--progress="$(PROGRESS)" \
		--target="$(TARGET)" \
		--output=. \
		.

.PHONY: validate
validate: ## Validate files license header
	docker run --rm -v $(CURDIR):/work -w /work golang:alpine sh -c 'go install github.com/kunalkushwaha/ltag@latest && ./scripts/validate/fileheader'
