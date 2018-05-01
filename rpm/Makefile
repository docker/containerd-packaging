CONTAINERD_URL=https://github.com/containerd/containerd
GIT_COMMIT:=209a7fc3e4a32ef71a8c7b50c68fc8398415badf
RPMBUILD=docker run --privileged --rm -i\
	-v $(CURDIR)/rpmbuild/BUILD:/root/rpmbuild/BUILD \
	-v $(CURDIR)/rpmbuild/BUILDROOT:/root/rpmbuild/BUILDROOT \
	-v $(CURDIR)/rpmbuild/RPMS:/root/rpmbuild/RPMS \
	-v $(CURDIR)/rpmbuild/SRPMS:/root/rpmbuild/SRPMS \
	-v $(CURDIR)/systemd:/systemd  
CHOWN=docker run --rm -v $(CURDIR):/v -w /v alpine chown
CHOWN_TO_USER=$(CHOWN) -R $(shell id -u):$(shell id -g)
RPMBUILD_FLAGS=-ba\
	--define '_gitcommit $(GIT_COMMIT)' \
	--define '_version $(VERSION)' \
	SPECS/containerd.spec

.PHONY: centos
centos: 
	$(RPMBUILD) rpmbuild-$@ $(RPMBUILD_FLAGS)
	$(CHOWN) -R $(shell id -u):$(shell id -g) rpmbuild

.PHONY: clean
clean:
	-$(CHOWN_TO_USER) rpmbuild 
	-rm -rf rpmbuild 
	-$(CHOWN_TO_USER) systemd
	-rm -rf systemd
