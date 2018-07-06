# containerd-packaging

# Usage:

## For Developers:

Making a developer package is as simple as:

```shell
make CONTAINERD_DIR=${GOPATH}/src/github.com/containerd/containerd <all|rpm|deb>
```

## For package maintainers:

* [deb package maintainers guide](debian/README.md)
* [rpm package maintainers guide](rpm/README.md)
