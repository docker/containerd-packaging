%bcond_without ctr
%bcond_with debug

%if %{with debug}
%global _dwz_low_mem_die_limit 0
%else
%global debug_package %{nil}
%endif

%if ! 0%{?gobuild:1}
%define gobuild(o:) go build -ldflags "${LDFLAGS:-} -B 0x$(head -c20 /dev/urandom|od -An -tx1|tr -d ' \\n')" -a -v -x %{?**};
%endif

%global import_path github.com/containerd/containerd

Name: containerd
Version: 1.1.0
%global commit 209a7fc3e4a32ef71a8c7b50c68fc8398415badf
%global tag v%{version}
Release: 1%{?dist}
Summary: An industry-standard container runtime
License: ASL 2.0
URL: https://containerd.io
Source0: https://%{import_path}/archive/%{tag}/containerd-%{version}.tar.gz
Source1: containerd.service
Source2: containerd.toml
ExclusiveArch: %{go_arches}
BuildRequires: systemd
%{?go_compiler:BuildRequires: compiler(go-compiler)}
BuildRequires: golang >= 1.10
BuildRequires: protobuf-compiler
BuildRequires: pkgconfig(protobuf) >= 3
BuildRequires: btrfs-progs-devel
%{?systemd_requires}
# https://github.com/containerd/containerd/issues/1508#issuecomment-335566293
Requires: runc >= 1.0.0
# vendored libraries
# awk '!/^($|[:space:]*#)/ {print "Provides: bundled(golang("$1")) = "$2}' vendor.conf | sort
Provides: bundled(golang(github.com/beorn7/perks)) = 4c0e84591b9aa9e6dcfdf3e020114cd81f89d5f9
Provides: bundled(golang(github.com/blang/semver)) = v3.1.0
Provides: bundled(golang(github.com/boltdb/bolt)) = e9cf4fae01b5a8ff89d0ec6b32f0d9c9f79aefdd
Provides: bundled(golang(github.com/BurntSushi/toml)) = a368813c5e648fee92e5f6c30e3944ff9d5e8895
Provides: bundled(golang(github.com/containerd/aufs)) = a7fbd554da7a9eafbe5a460a421313a9fd18d988
Provides: bundled(golang(github.com/containerd/btrfs)) = 2e1aa0ddf94f91fa282b6ed87c23bf0d64911244
Provides: bundled(golang(github.com/containerd/cgroups)) = fe281dd265766145e943a034aa41086474ea6130
Provides: bundled(golang(github.com/containerd/console)) = cb7008ab3d8359b78c5f464cb7cf160107ad5925
Provides: bundled(golang(github.com/containerd/continuity)) = 3e8f2ea4b190484acb976a5b378d373429639a1a
Provides: bundled(golang(github.com/containerd/cri)) = v1.0.0
Provides: bundled(golang(github.com/containerd/fifo)) = 3d5202aec260678c48179c56f40e6f38a095738c
Provides: bundled(golang(github.com/containerd/go-cni)) = f2d7272f12d045b16ed924f50e91f9f9cecc55a7
Provides: bundled(golang(github.com/containerd/go-runc)) = bcb223a061a3dd7de1a89c0b402a60f4dd9bd307
Provides: bundled(golang(github.com/containerd/typeurl)) = f6943554a7e7e88b3c14aad190bf05932da84788
Provides: bundled(golang(github.com/containerd/zfs)) = 9a0b8b8b5982014b729cd34eb7cd7a11062aa6ec
Provides: bundled(golang(github.com/containernetworking/cni)) = v0.6.0
Provides: bundled(golang(github.com/containernetworking/plugins)) = v0.7.0
Provides: bundled(golang(github.com/coreos/go-systemd)) = 48702e0da86bd25e76cfef347e2adeb434a0d0a6
Provides: bundled(golang(github.com/davecgh/go-spew)) = v1.1.0
Provides: bundled(golang(github.com/docker/distribution)) = b38e5838b7b2f2ad48e06ec4b500011976080621
Provides: bundled(golang(github.com/docker/docker)) = 86f080cff0914e9694068ed78d503701667c4c00
Provides: bundled(golang(github.com/docker/go-events)) = 9461782956ad83b30282bf90e31fa6a70c255ba9
Provides: bundled(golang(github.com/docker/go-metrics)) = 4ea375f7759c82740c893fc030bc37088d2ec098
Provides: bundled(golang(github.com/docker/go-units)) = v0.3.1
Provides: bundled(golang(github.com/docker/spdystream)) = 449fdfce4d962303d702fec724ef0ad181c92528
Provides: bundled(golang(github.com/emicklei/go-restful)) = ff4f55a206334ef123e4f79bbf348980da81ca46
Provides: bundled(golang(github.com/ghodss/yaml)) = 73d445a93680fa1a78ae23a5839bad48f32ba1ee
Provides: bundled(golang(github.com/godbus/dbus)) = c7fdd8b5cd55e87b4e1f4e372cdb1db61dd6c66f
Provides: bundled(golang(github.com/gogo/googleapis)) = 08a7655d27152912db7aaf4f983275eaf8d128ef
Provides: bundled(golang(github.com/gogo/protobuf)) = v1.0.0
Provides: bundled(golang(github.com/golang/glog)) = 44145f04b68cf362d9c4df2182967c2275eaefed
Provides: bundled(golang(github.com/golang/protobuf)) = 1643683e1b54a9e88ad26d98f81400c8c9d9f4f9
Provides: bundled(golang(github.com/google/go-cmp)) = v0.1.0
Provides: bundled(golang(github.com/google/gofuzz)) = 44d81051d367757e1c7c6a5a86423ece9afcf63c
Provides: bundled(golang(github.com/gotestyourself/gotestyourself)) = 44dbf532bbf5767611f6f2a61bded572e337010a
Provides: bundled(golang(github.com/grpc-ecosystem/go-grpc-prometheus)) = 6b7015e65d366bf3f19b2b2a000a831940f0f7e0
Provides: bundled(golang(github.com/hashicorp/errwrap)) = 7554cd9344cec97297fa6649b055a8c98c2a1e55
Provides: bundled(golang(github.com/hashicorp/go-multierror)) = ed905158d87462226a13fe39ddf685ea65f1c11f
Provides: bundled(golang(github.com/json-iterator/go)) = 1.0.4
Provides: bundled(golang(github.com/matttproud/golang_protobuf_extensions)) = v1.0.0
Provides: bundled(golang(github.com/Microsoft/go-winio)) = v0.4.5
Provides: bundled(golang(github.com/Microsoft/hcsshim)) = v0.6.7
Provides: bundled(golang(github.com/mistifyio/go-zfs)) = 166add352731e515512690329794ee593f1aaff2
Provides: bundled(golang(github.com/opencontainers/go-digest)) = 21dfd564fd89c944783d00d069f33e3e7123c448
Provides: bundled(golang(github.com/opencontainers/image-spec)) = v1.0.1
Provides: bundled(golang(github.com/opencontainers/runc)) = 69663f0bd4b60df09991c08812a60108003fa340
Provides: bundled(golang(github.com/opencontainers/runtime-spec)) = v1.0.1
Provides: bundled(golang(github.com/opencontainers/runtime-tools)) = 6073aff4ac61897f75895123f7e24135204a404d
Provides: bundled(golang(github.com/opencontainers/selinux)) = 4a2974bf1ee960774ffd517717f1f45325af0206
Provides: bundled(golang(github.com/pborman/uuid)) = c65b2f87fee37d1c7854c9164a450713c28d50cd
Provides: bundled(golang(github.com/pkg/errors)) = v0.8.0
Provides: bundled(golang(github.com/pmezard/go-difflib)) = v1.0.0
Provides: bundled(golang(github.com/prometheus/client_golang)) = f4fb1b73fb099f396a7f0036bf86aa8def4ed823
Provides: bundled(golang(github.com/prometheus/client_model)) = 99fa1f4be8e564e8a6b613da7fa6f46c9edafc6c
Provides: bundled(golang(github.com/prometheus/common)) = 89604d197083d4781071d3c65855d24ecfb0a563
Provides: bundled(golang(github.com/prometheus/procfs)) = cb4147076ac75738c9a7d279075a253c0cc5acbd
Provides: bundled(golang(github.com/seccomp/libseccomp-golang)) = 32f571b70023028bd57d9288c20efbcb237f3ce0
Provides: bundled(golang(github.com/sirupsen/logrus)) = v1.0.0
Provides: bundled(golang(github.com/spf13/pflag)) = v1.0.0
Provides: bundled(golang(github.com/stevvooe/ttrpc)) = d4528379866b0ce7e9d71f3eb96f0582fc374577
Provides: bundled(golang(github.com/syndtr/gocapability)) = db04d3cc01c8b54962a58ec7e491717d06cfcc16
Provides: bundled(golang(github.com/tchap/go-patricia)) = 5ad6cdb7538b0097d5598c7e57f0a24072adf7dc
Provides: bundled(golang(github.com/urfave/cli)) = 7bc6a0acffa589f415f88aca16cc1de5ffd66f9c
Provides: bundled(golang(golang.org/x/crypto)) = 49796115aa4b964c318aad4f3084fdb41e9aa067
Provides: bundled(golang(golang.org/x/net)) = 7dcfb8076726a3fdd9353b6b8a1f1b6be6811bd6
Provides: bundled(golang(golang.org/x/sync)) = 450f422ab23cf9881c94e2db30cac0eb1b7cf80c
Provides: bundled(golang(golang.org/x/sys)) = 314a259e304ff91bd6985da2a7149bbf91237993
Provides: bundled(golang(golang.org/x/text)) = 19e51611da83d6be54ddafce4a4af510cb3e9ea4
Provides: bundled(golang(golang.org/x/time)) = f51c12702a4d776e4c1fa9b0fabab841babae631
Provides: bundled(golang(google.golang.org/genproto)) = d80a6e20e776b0b17a324d0ba1ab50a39c8e8944
Provides: bundled(golang(google.golang.org/grpc)) = v1.10.1
Provides: bundled(golang(gopkg.in/inf.v0)) = 3887ee99ecf07df5b447e9b00d9c0b2adaa9f3e4
Provides: bundled(golang(gopkg.in/yaml.v2)) = 53feefa2559fb8dfa8d81baad31be332c97d6c77
Provides: bundled(golang(k8s.io/api)) = 7e796de92438aede7cb5d6bcf6c10f4fa65db560
Provides: bundled(golang(k8s.io/apimachinery)) = fcb9a12f7875d01f8390b28faedc37dcf2e713b9
Provides: bundled(golang(k8s.io/apiserver)) = 4a8377c547bbff4576a35b5b5bf4026d9b5aa763
Provides: bundled(golang(k8s.io/client-go)) = b9a0cf870f239c4a4ecfd3feb075a50e7cbe1473
Provides: bundled(golang(k8s.io/kubernetes)) = v1.10.0
Provides: bundled(golang(k8s.io/utils)) = 258e2a2fa64568210fbd6267cf1d8fd87c3cb86e


%description
containerd is an industry-standard container runtime with an emphasis on
simplicity, robustness and portability. It is available as a daemon for Linux
and Windows, which can manage the complete container lifecycle of its host
system: image transfer and storage, container execution and supervision,
low-level storage and network attachments, etc.


%prep
%autosetup -n containerd-%{version}


%build
mkdir -p src/%(dirname %{import_path})
ln -s ../../.. src/%{import_path}
export GOPATH=$(pwd):%{gopath}
export LDFLAGS="-X %{import_path}/version.Package=%{import_path} -X %{import_path}/version.Version=%{tag} -X %{import_path}/version.Revision=%{commit}"
%gobuild -o bin/containerd %{import_path}/cmd/containerd
%gobuild -o bin/containerd-shim %{import_path}/cmd/containerd-shim
%{?with_ctr:%gobuild -o bin/ctr %{import_path}/cmd/ctr}


%install
install -D -m 0755 bin/containerd %{buildroot}%{_bindir}/containerd
install -D -m 0755 bin/containerd-shim %{buildroot}%{_bindir}/containerd-shim
%{?with_ctr:install -D -m 0755 bin/ctr %{buildroot}%{_bindir}/ctr}
install -D -m 0644 %{S:1} %{buildroot}%{_unitdir}/containerd.service
install -D -m 0644 %{S:2} %{buildroot}%{_sysconfdir}/containerd/config.toml


%post
%systemd_post containerd.service


%preun
%systemd_preun containerd.service


%postun
%systemd_postun_with_restart containerd.service


%files
%license LICENSE.code
%doc README.md
%{_bindir}/containerd
%{_bindir}/containerd-shim
%{?with_ctr:%{_bindir}/ctr}
%{_unitdir}/containerd.service
%{_sysconfdir}/containerd
%config(noreplace) %{_sysconfdir}/containerd/config.toml


%changelog
* Fri Jun 22 2018 Eli Uriegas <eli.uriegas@docker.com> - 1.1.0-1
- Update to 1.1.0

* Wed Apr 04 2018 Carl George <carl@george.computer> - 1.0.3-1
- Latest upstream

* Wed Feb 07 2018 Fedora Release Engineering <releng@fedoraproject.org> - 1.0.1-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_28_Mass_Rebuild

* Mon Jan 22 2018 Carl George <carl@george.computer> - 1.0.1-1
- Latest upstream

* Wed Dec 06 2017 Carl George <carl@george.computer> - 1.0.0-1
- Latest upstream

* Fri Nov 10 2017 Carl George <carl@george.computer> - 1.0.0-0.5.beta.3
- Latest upstream

* Thu Oct 19 2017 Carl George <carl@george.computer> - 1.0.0-0.4.beta.2
- Own /etc/containerd

* Thu Oct 12 2017 Carl George <carl@george.computer> - 1.0.0-0.3.beta.2
- Latest upstream
- Require runc 1.0.0 https://github.com/containerd/containerd/issues/1508#issuecomment-335566293

* Mon Oct 09 2017 Carl George <carl@george.computer> - 1.0.0-0.2.beta.1
- Add provides for vendored dependencies
- Add ctr command

* Wed Oct 04 2017 Carl George <carl@george.computer> - 1.0.0-0.1.beta.1
- Initial package
