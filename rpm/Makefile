CONTAINERD_REF=master
CONTAINERD_URL=https://github.com/containerd/containerd
#GIT_COMMIT:=773c489c9c1b21a6d78b5c538cd395416ec50f88
GIT_COMMIT:=1
RPMBUILD=docker run --privileged --rm -i\
	-v $(CURDIR)/rpmbuild/BUILD:/root/rpmbuild/BUILD \
	-v $(CURDIR)/rpmbuild/BUILDROOT:/root/rpmbuild/BUILDROOT \
	-v $(CURDIR)/rpmbuild/RPMS:/root/rpmbuild/RPMS \
	-v $(CURDIR)/rpmbuild/SRPMS:/root/rpmbuild/SRPMS \
	-v $(CURDIR)/systemd:/systemd  
CHOWN=docker run --rm -v $(CURDIR):/v -w /v alpine chown
RPMBUILD_FLAGS=-ba\
	--define '_gitcommit $(GIT_COMMIT)' \
	--define '_version $(VERSION)' \
	SPECS/containerd.spec

.PHONY: centos
centos: 
	$(RPMBUILD) rpmbuild-$@ $(RPMBUILD_FLAGS)
	$(CHOWN) -R $(shell id -u):$(shell id -g) rpmbuild

.PHONY: VERSION
VERSION:
	echo $(VERSION)
