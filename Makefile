GOARCH=$(shell docker run --rm golang go env GOARCH 2>/dev/null)
VERSION?=1.1.0
TAG?=v$(VERSION)
REF?=$(shell git ls-remote https://github.com/containerd/containerd.git | grep 'refs/tags/$(TAG)$$' | awk '{print $$1}')
GOVERSION?=1.10.3
GO_DL_URL?=$(shell GOVERSION=$(GOVERSION) ./scripts/gen-go-dl-url)

BUILDER_IMAGE=containerd-builder-$@-$(GOARCH):$(TAG)
BUILD=docker build \
	 --build-arg GO_DL_URL="$(GO_DL_URL)" \
	 --build-arg VERSION="$(VERSION)" \
	 --build-arg REF="$(REF)" \
	 -f dockerfiles/$@.dockerfile \
	 -t $(BUILDER_IMAGE) .

VOLUME_MOUNTS=-v "$(CURDIR)/build/DEB:/out" \
	-v "$(CURDIR)/build/RPMS:/root/rpmbuild/RPMS" \
	-v "$(CURDIR)/build/SRPMS:/root/rpmbuild/SRPMS"
ifdef CONTAINERD_DIR
	# Allow for overriding the main containerd directory, packaging will look weird but you'll have something
	VOLUME_MOUNTS+=-v "$(shell readlink -e $(CONTAINERD_DIR)):/go/src/github.com/containerd/containerd"
endif
RUN=docker run --rm  $(VOLUME_MOUNTS) -it $(BUILDER_IMAGE)

CHOWN=docker run --rm -v $(CURDIR):/v -w /v alpine chown
CHOWN_TO_USER=$(CHOWN) -R $(shell id -u):$(shell id -g)

RPMBUILD_FLAGS=-ba\
	--define '_gitcommit $(REF)' \
	--define '_version $(VERSION)' \
	SPECS/containerd.spec

all: rpm deb

.PHONY: clean
clean:
	-$(CHOWN_TO_USER) build/
	-$(RM) -r build/

.PHONY: rpm
rpm:
	$(BUILD)
	$(RUN) $(RPMBUILD_FLAGS)
	$(CHOWN_TO_USER) build/

.PHONY: deb
deb:
	$(BUILD)
	$(RUN)
	$(CHOWN_TO_USER) build/
