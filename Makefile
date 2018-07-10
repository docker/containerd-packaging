GOARCH=$(shell docker run --rm golang go env GOARCH 2>/dev/null)
REF?=master
GOVERSION?=1.10.3
GO_DL_URL?=$(shell GOVERSION=$(GOVERSION) ./scripts/gen-go-dl-url)

BUILDER_IMAGE=containerd-builder-$@-$(GOARCH):$(shell git rev-parse --short HEAD)
BUILD=docker build \
	 --build-arg GO_DL_URL="$(GO_DL_URL)" \
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
RUN=docker run --rm $(VOLUME_MOUNTS) -t $(BUILDER_IMAGE)

CHOWN=docker run --rm -v $(CURDIR):/v -w /v alpine chown
CHOWN_TO_USER=$(CHOWN) -R $(shell id -u):$(shell id -g)

all: rpm deb

.PHONY: clean
clean:
	-$(CHOWN_TO_USER) build/
	-$(RM) -r build/

.PHONY: rpm
rpm:
	$(BUILD)
	$(RUN)
	$(CHOWN_TO_USER) build/

.PHONY: deb
deb:
	$(BUILD)
	$(RUN)
	$(CHOWN_TO_USER) build/
