# containerd-packaging

# Usage:

To build a distro-specific package (rpm or deb):

```bash
make clean
make docker.io/library/<distro>:<version> [docker.io/library/<distro>:<version> ...]

# for example:
# make quay.io/centos/centos:stream9
# make docker.io/library/ubuntu:24.04
```

After build completes, packages can be found in the `build` directory.

## Specifying the version to build

By default, packages are built from HEAD of the `release/1.7` branch, as
defines in [common/common.mk]. The version of runc defaults to the version
as specified by the containerd project through the [script/setup/runc-version]
file in the containerd repository.

Use the `REF` and `RUNC_REF` make variables to specify the versions to build.
The provided values must be a valid Git reference, which can be a commit
(e.g., `ae71819` or `ae71819c4f5e67bb4d5ae76a6b735f29cc25774e`), branch
(e.g. `main` or `release/1.7`), or tag (e.g. `v1.7.18`).

The following example builds packages for containerd v1.7.18 with
runc v1.1.12 for Ubuntu 24.04:

```bash
make REF=v1.7.18 RUNC_REF=v1.1.12 docker.io/library/ubuntu:24.04
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


[common/common.mk]: https://github.com/docker/containerd-packaging/blob/main/common/common.mk#L19
[script/setup/runc-version]: https://github.com/containerd/containerd/blob/v1.7.18/script/setup/runc-version
