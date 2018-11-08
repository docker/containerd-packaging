GOARCH=$(shell docker run --rm golang go env GOARCH 2>/dev/null)
ARCH:=$(shell uname -m)
REF?=$(shell git ls-remote https://github.com/containerd/containerd.git | grep master | awk '{print $$1}')
RUNC_REF?=58592df56734acf62e574865fe40b9e53e967910
GOVERSION?=1.10.3
GOLANG_IMAGE?=golang:1.10.3

# need specific repos for s390x
ifeq ($(ARCH),s390x)
	# no s390x for fedora
	DOCKER_FILE_PREFIX=centos.s390x
else
	DOCKER_FILE_PREFIX=centos
endif

ifdef BUILD_IMAGE
	BUILD_IMAGE_FLAG=--build-arg BUILD_IMAGE="$(BUILD_IMAGE)"
endif
BUILDER_IMAGE=containerd-builder-$@-$(GOARCH):$(shell git rev-parse --short HEAD)
BUILD=docker build \
	$(BUILD_IMAGE_FLAG) \
	--build-arg GOLANG_IMAGE="$(GOLANG_IMAGE)" \
	--build-arg REF="$(REF)" \
	--build-arg RUNC_REF="$(RUNC_REF)"

VOLUME_MOUNTS=-v "$(CURDIR)/build/DEB:/out" \
	-v "$(CURDIR)/build/$@/RPMS:/root/rpmbuild/RPMS" \
	-v "$(CURDIR)/build/$@/SRPMS:/root/rpmbuild/SRPMS"
ifdef CONTAINERD_DIR
	# Allow for overriding the main containerd directory, packaging will look weird but you'll have something
	VOLUME_MOUNTS+=-v "$(shell readlink -e $(CONTAINERD_DIR)):/go/src/github.com/containerd/containerd"
endif
RUN=docker run --rm $(VOLUME_MOUNTS) -t $(BUILDER_IMAGE)

CHOWN=docker run --rm -v $(CURDIR):/v -w /v alpine chown
CHOWN_TO_USER=$(CHOWN) -R $(shell id -u):$(shell id -g)

CONTAINERD_REPO?=containerd/containerd
CONTAINERD_BRANCH?=release/1.1
CONTAINERD_DIR?=$(shell basename $(CONTAINERD_REPO))
CONTAINERD_MOUNT?=C:\gopath\src\github.com\containerd\containerd
WINDOWS_BINARIES=containerd ctr
WINDOWS_BUILDER=windows-fips-builder

# Build tags seccomp and apparmor are needed by CRI plugin.
BUILDTAGS ?= seccomp apparmor
GO_TAGS=$(if $(BUILDTAGS),-tags "$(BUILDTAGS)",)
GO_LDFLAGS=-ldflags '-s -w -X $(PKG)/version.Version=$(VERSION) -X $(PKG)/version.Revision=$(REVISION) -X $(PKG)/version.Package=$(PKG) $(EXTRA_LDFLAGS)'

all: rpm deb

.PHONY: clean
clean:
	-$(CHOWN_TO_USER) build/
	-$(CHOWN_TO_USER) artifacts/
	-$(RM) -r build/
	-$(RM) -r artifacts
	-$(RM) -r $(CONTAINERD_DIR)

# For deb packages only need to build one package
.PHONY: deb
deb:
	$(BUILD) \
	 -f dockerfiles/$@.dockerfile \
	 -t $(BUILDER_IMAGE) .
	$(RUN)
	$(CHOWN_TO_USER) build/

.PHONY: rpm
rpm:  centos-7 fedora-28

.PHONY: centos-7
centos-7:
	$(BUILD) \
	-f dockerfiles/$(DOCKER_FILE_PREFIX).dockerfile \
	 -t $(BUILDER_IMAGE) .
	$(RUN)
	$(CHOWN_TO_USER) build/

.PHONY: fedora-%
fedora-%:
	$(BUILD) \
	-f dockerfiles/$@.dockerfile \
	-t $(BUILDER_IMAGE) .
	$(RUN)
	$(CHOWN_TO_USER) build/

.PHONY: sles
sles:
	$(BUILD) \
	-f dockerfiles/$@.dockerfile \
	-t $(BUILDER_IMAGE) .
	$(RUN)
	$(CHOWN_TO_USER) build/

$(WINDOWS_BUILDER):
	docker build -f dockerfiles/windows.dockerfile -t $(WINDOWS_BUILDER) .

$(CONTAINERD_DIR):
	git clone git@github.com:$(CONTAINERD_REPO)
	git -C $(CONTAINERD_DIR) checkout $(CONTAINERD_BRANCH)

.PHONY: windows-binaries
windows-binaries: $(CONTAINERD_DIR) $(WINDOWS_BUILDER)
	for binary in $(WINDOWS_BINARIES); do \
		(set -x; docker run --rm -v "$(CURDIR)/$(CONTAINERD_DIR):$(CONTAINERD_MOUNT)" -w "$(CONTAINERD_MOUNT)" $(WINDOWS_BUILDER) $(GO_BUILD_FLAGS) $(GO_LDFLAGS) $(GO_TAGS) ./cmd/$$binary) || exit 1; \
	done
	ls $(CONTAINERD_DIR) | grep '.exe'
