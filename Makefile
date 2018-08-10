GOARCH=$(shell docker run --rm golang go env GOARCH 2>/dev/null)
REF?=master
RUNC_REF?=v1.0.0-rc5
OFFLINE_INSTALL_REF?=20eddbfe5d4d894cfee6974829c7d3981acba1be
GOVERSION?=1.10.3
GO_DL_URL?=$(shell GOVERSION=$(GOVERSION) ./scripts/gen-go-dl-url)

BUILDER_IMAGE=containerd-builder-$@-$(GOARCH):$(shell git rev-parse --short HEAD)
BUILD=docker build \
	 --build-arg GO_DL_URL="$(GO_DL_URL)" \
	 --build-arg REF="$(REF)" \
	 --build-arg OFFLINE_INSTALL_REF="$(OFFLINE_INSTALL_REF)" \
	 -f dockerfiles/$@.dockerfile \
	 -t $(BUILDER_IMAGE) .

VOLUME_MOUNTS=-v "$(CURDIR)/build/DEB:/out" \
	-v "$(CURDIR)/build/RPMS:/root/rpmbuild/RPMS" \
	-v "$(CURDIR)/build/SRPMS:/root/rpmbuild/SRPMS"
ifdef CONTAINERD_DIR
	# Allow for overriding the main containerd directory, packaging will look weird but you'll have something
	VOLUME_MOUNTS+=-v "$(shell readlink -e $(CONTAINERD_DIR)):/go/src/github.com/containerd/containerd"
endif
RUN=docker run --rm $(VOLUME_MOUNTS) -t $(BUILDER_IMAGE)

CHOWN=docker run --rm -v $(CURDIR):/v -w /v alpine chown
CHOWN_TO_USER=$(CHOWN) -R $(shell id -u):$(shell id -g)

# Default to `ctr` if it's around, else use `docker-containerd-ctr`
CTR=$(shell if which ctr > /dev/null 2>/dev/null; then which ctr; else which docker-containerd-ctr; fi)
ifeq ("$(CTR)", "$(shell which docker-containerd-ctr)")
CONTAINERD_SOCK:=/var/run/docker/containerd/docker-containerd.sock
else
CONTAINERD_SOCK:=/var/run/containerd/containerd.sock
endif

CONTAINERD_REPO?=containerd/containerd
CONTAINERD_BRANCH?=release/1.1
CONTAINERD_DIR?=$(shell basename $(CONTAINERD_REPO))
CONTAINERD_MOUNT?=C:\go\src\github.com\containerd\containerd
WINDOWS_BINARIES=containerd ctr
WINDOWS_BUILDER=dockereng/windows-go-builder:go1.10.3-win1803

# Build tags seccomp and apparmor are needed by CRI plugin.
BUILDTAGS ?= seccomp apparmor
GO_TAGS=$(if $(BUILDTAGS),-tags "$(BUILDTAGS)",)
GO_LDFLAGS=-ldflags '-s -w -X $(PKG)/version.Version=$(VERSION) -X $(PKG)/version.Revision=$(REVISION) -X $(PKG)/version.Package=$(PKG) $(EXTRA_LDFLAGS)'

all: rpm deb

.PHONY: clean
clean:
	-$(CHOWN_TO_USER) build/
	-$(RM) -r build/
	-$(RM) runc.tar
	-$(RM) -r $(CONTAINERD_DIR)

runc.tar:
	sudo $(CTR) -a $(CONTAINERD_SOCK) content fetch docker.io/docker/runc:$(RUNC_REF)
	sudo $(CTR) -a $(CONTAINERD_SOCK) image export $@ docker.io/docker/runc:$(RUNC_REF)

.PHONY: rpm
rpm: runc.tar
	$(BUILD)
	$(RUN)
	$(CHOWN_TO_USER) build/

.PHONY: deb
deb: runc.tar
	$(BUILD)
	$(RUN)
	$(CHOWN_TO_USER) build/

$(CONTAINERD_DIR):
	git clone git@github.com:$(CONTAINERD_REPO)
	git -C $(CONTAINERD_DIR) checkout $(CONTAINERD_BRANCH)

.PHONY: windows-binaries
windows-binaries: $(CONTAINERD_DIR)
	for binary in $(WINDOWS_BINARIES); do \
		(set -x; docker run --rm -v "$(CURDIR)/$(CONTAINERD_DIR):$(CONTAINERD_MOUNT)" -w "$(CONTAINERD_MOUNT)" $(WINDOWS_BUILDER) $(GO_BUILD_FLAGS) $(GO_LDFLAGS) $(GO_TAGS) ./cmd/$$binary) || exit 1; \
	done
	ls $(CONTAINERD_DIR) | grep '.exe'
