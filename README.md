# containerd-packaging

# Usage:

To build a distro-specific package (rpm or deb):

```bash
make clean
make docker.io/library/<distro>:<version> [docker.io/library/<distro>:<version> ...]

# for example:
# make docker.io/library/centos:7
# make docker.io/library/ubuntu:jammy
```

After build completes, packages can be found in the `build` directory.

To build static binaries:

```bash
make clean
make static
```

## Building a package from a local source directory

Specify the path to the local source directory using `CONTAINERD_DIR` and/or
`RUNC_DIR`:

```bash
make REF=<git reference> CONTAINERD_DIR=<path to repository> docker.io/library/<distro>:<version>
```

For example:

```bash
make clean
make REF=HEAD CONTAINERD_DIR=/home/me/go/src/github.com/containerd/containerd docker.io/library/ubuntu:jammy
```

## For package maintainers:

* [deb package maintainers guide](debian/README.md)
* [rpm package maintainers guide](rpm/README.md)
