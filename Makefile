GOARCH=$(shell docker run --rm golang go env GOARCH 2>/dev/null)
TAG?=v1.1.0
REF?=$(shell git ls-remote https://github.com/containerd/containerd.git | grep 'refs/tags/$(TAG)$$' | awk '{print $$1}')
GOVERSION?=1.10.1

BUILDER_IMAGE=containerd-builder-$@-$(GOARCH):$(TAG)
BUILD=docker build \
	 --build-arg GOARCH="$(GOARCH)" \
	 --build-arg GOVERSION="$(GOVERSION)" \
	 --build-arg TAG="$(TAG)" \
	 --build-arg REF="$(REF)" \
	 -f dockerfiles/$@.dockerfile \
	 -t $(BUILDER_IMAGE) .
RUN=docker run --rm -v "$(CURDIR)/build/$@:/out" -it $(BUILDER_IMAGE)
CHOWN=docker run --rm -v $(CURDIR):/v -w /v alpine chown
CHOWN_TO_USER=$(CHOWN) -R $(shell id -u):$(shell id -g)

.PHONY: clean
clean:
	$(CHOWN_TO_USER) build/
	$(RM) -r build/

.PHONY: deb
deb: ubuntu-xenial

.PHONY: ubuntu-xenial
ubuntu-xenial:
	$(BUILD)
	$(RUN)
	$(CHOWN_TO_USER) build/
