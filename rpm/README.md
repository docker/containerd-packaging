# rpm package maintainers guide

## Prepping a release

For releases you should first have a tagged release on the
[containerd](https://github.com/containerd/containerd/releases)
repository.

Afterwards test if you can actually build the release with:

```
make REF=${TAG} rpm
```

If you can actually build the package then start prepping
your release by adding a changelog entry in the
[`rpm/containerd.spec`](containerd.spec) with the format:

```
./scripts/new-rpm-release <VERSION>
```

This will add an entry into the changelog for the specified VERSION
and will also increment the rpm packaging version if the specified
VERSION is already there.

**NOTE**: Make sure to fill out the bullets for the changelog

## Building the release:

Releases can then be built with:

```
make REF=${TAG} rpm
```
