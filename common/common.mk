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
GOLANG_VERSION?=$(shell grep "ARG GOLANG_VERSION" src/github.com/containerd/containerd/contrib/Dockerfile.test | awk -F'=' '{print $$2}')

# Allow GOLANG_VERSION to be overridden through GOVERSION.
#
# We're using a separate variable for this to account for make being called as
# either `GOVERSION=x make foo` or `make GOVERSION=x foo`, while also accounting
# for `GOVERSION` to be an empty string (which may happen when triggered by some
# Jenkins jobs in our pipeline).
ifneq ($(strip $(GOVERSION)),)
	GOLANG_VERSION=$(GOVERSION)
endif

GOLANG_IMAGE=golang:$(GOLANG_VERSION)
