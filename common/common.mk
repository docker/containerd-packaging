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

# NOTE: When overriding CONTAINERD_REMOTE, make sure to also specify
#       GOVERSION, as it's hardcoded to look in the upstream repository
CONTAINERD_REMOTE ?=https://github.com/containerd/containerd.git
RUNC_REMOTE       ?=https://github.com/opencontainers/runc.git
REF?=HEAD

# Select the default version of Golang and runc based on the containerd source.
GOVERSION?=$(shell grep "ARG GOLANG_VERSION" src/github.com/containerd/containerd/contrib/Dockerfile.test | awk -F'=' '{print $$2}')
RUNC_REF?=$(shell scripts/determine-runc-version)

GOLANG_IMAGE=golang:$(GOVERSION)
ifeq ($(OS),Windows_NT)
       GOLANG_IMAGE=docker.io/library/golang:$(GOVERSION)
else
       GOLANG_IMAGE=docker.io/library/golang:$(GOVERSION)-buster
endif
GOARCH=$(shell docker run --rm $(GOLANG_IMAGE) go env GOARCH 2>/dev/null)
