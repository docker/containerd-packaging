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

GOARCH=$(shell docker run --rm golang go env GOARCH 2>/dev/null)
REF?=HEAD
RUNC_REF?=dc9208a3303feef5b3839f4323d9beb36df0a9dd

ifdef CONTAINERD_DIR
GOVERSION?=$(shell grep "ARG GOLANG_VERSION" $(CONTAINERD_DIR)/contrib/Dockerfile.test | awk -F'=' '{print $$2}')
else
GOVERSION?=$(shell curl -fsSL "https://raw.githubusercontent.com/containerd/containerd/$(REF)/contrib/Dockerfile.test" | grep "ARG GOLANG_VERSION" | awk -F'=' '{print $$2}')
endif

GOLANG_IMAGE=golang:$(GOVERSION)
ifeq ($(OS),Windows_NT)
       GOLANG_IMAGE=docker.io/library/golang:$(GOVERSION)
else
       GOLANG_IMAGE=docker.io/library/golang:$(GOVERSION)-buster
endif
BUILDER_IMAGE=containerd-builder-$@-$(GOARCH):$(shell git rev-parse --short HEAD)

ARCH:=$(shell uname -m)

BUILD_ARGS=--build-arg GOLANG_IMAGE="$(GOLANG_IMAGE)" \
	--build-arg BUILD_IMAGE="$(BUILD_IMAGE)" \
	--build-arg BASE="$(BUILD_BASE)"
