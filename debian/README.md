# Debian package maintainers guide

## Prepping a release

For releases you should first have a tagged release on the
[containerd](https://github.com/containerd/containerd/releases)
repository.

Afterwards test if you can actually build the release with (for example):

```bash
make REF=${TAG} docker.io/library/ubuntu:bionic
```

If you can actually build the package then start prepping
your release by adding an entry in the [`debian/changelog`](changelog) with the
format:

```bash
./scripts/new-deb-release <VERSION>
```

This will add an entry into the changelog for the specified VERSION
and will also increment the debian packaging version if the specified
VERSION is already there.

> **NOTE**: Make sure to fill out the bullets for the changelog

## Building the release:

Releases can then be built with:

```bash
make REF=${TAG} docker.io/library/ubuntu:bionic
```

or

```bash
make REF=${TAG} BUILD_IMAGE=docker.io/library/ubuntu:bionic
```
