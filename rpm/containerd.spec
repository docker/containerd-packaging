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
Version: 1.0.3
%global commit 773c489c9c1b21a6d78b5c538cd395416ec50f88
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
BuildRequires: golang >= 1.9
BuildRequires: protobuf-compiler
BuildRequires: pkgconfig(protobuf) >= 3
BuildRequires: btrfs-progs-devel
%{?systemd_requires}
# https://github.com/containerd/containerd/issues/1508#issuecomment-335566293
Requires: runc >= 1.0.0
# vendored libraries
# awk '{print "Provides: bundled(golang("$1")) = "$2}' containerd-*/vendor.conf | sort
Provides: bundled(golang(github.com/beorn7/perks)) = 4c0e84591b9aa9e6dcfdf3e020114cd81f89d5f9
Provides: bundled(golang(github.com/boltdb/bolt)) = e9cf4fae01b5a8ff89d0ec6b32f0d9c9f79aefdd
Provides: bundled(golang(github.com/BurntSushi/toml)) = a368813c5e648fee92e5f6c30e3944ff9d5e8895
Provides: bundled(golang(github.com/containerd/btrfs)) = 2e1aa0ddf94f91fa282b6ed87c23bf0d64911244
Provides: bundled(golang(github.com/containerd/cgroups)) = fe281dd265766145e943a034aa41086474ea6130
Provides: bundled(golang(github.com/containerd/console)) = 84eeaae905fa414d03e07bcd6c8d3f19e7cf180e
Provides: bundled(golang(github.com/containerd/continuity)) = cf279e6ac893682272b4479d4c67fd3abf878b4e
Provides: bundled(golang(github.com/containerd/fifo)) = fbfb6a11ec671efbe94ad1c12c2e98773f19e1e6
Provides: bundled(golang(github.com/containerd/go-runc)) = 4f6e87ae043f859a38255247b49c9abc262d002f
Provides: bundled(golang(github.com/containerd/typeurl)) = f6943554a7e7e88b3c14aad190bf05932da84788
Provides: bundled(golang(github.com/coreos/go-systemd)) = 48702e0da86bd25e76cfef347e2adeb434a0d0a6
Provides: bundled(golang(github.com/davecgh/go-spew)) = v1.1.0
Provides: bundled(golang(github.com/dmcgowan/go-tar)) = go1.10
Provides: bundled(golang(github.com/docker/go-events)) = 9461782956ad83b30282bf90e31fa6a70c255ba9
Provides: bundled(golang(github.com/docker/go-metrics)) = 8fd5772bf1584597834c6f7961a530f06cbfbb87
Provides: bundled(golang(github.com/docker/go-units)) = v0.3.1
Provides: bundled(golang(github.com/godbus/dbus)) = c7fdd8b5cd55e87b4e1f4e372cdb1db61dd6c66f
Provides: bundled(golang(github.com/gogo/protobuf)) = v0.5
Provides: bundled(golang(github.com/golang/protobuf)) = 1643683e1b54a9e88ad26d98f81400c8c9d9f4f9
Provides: bundled(golang(github.com/grpc-ecosystem/go-grpc-prometheus)) = 6b7015e65d366bf3f19b2b2a000a831940f0f7e0
Provides: bundled(golang(github.com/matttproud/golang_protobuf_extensions)) = v1.0.0
Provides: bundled(golang(github.com/Microsoft/go-winio)) = v0.4.4
Provides: bundled(golang(github.com/Microsoft/hcsshim)) = v0.6.7
Provides: bundled(golang(github.com/Microsoft/opengcs)) = v0.3.2
Provides: bundled(golang(github.com/opencontainers/go-digest)) = 21dfd564fd89c944783d00d069f33e3e7123c448
Provides: bundled(golang(github.com/opencontainers/image-spec)) = v1.0.0
Provides: bundled(golang(github.com/opencontainers/runc)) = 9f9c96235cc97674e935002fc3d78361b696a69e
Provides: bundled(golang(github.com/opencontainers/runtime-spec)) = v1.0.0
Provides: bundled(golang(github.com/pkg/errors)) = v0.8.0
Provides: bundled(golang(github.com/pmezard/go-difflib)) = v1.0.0
Provides: bundled(golang(github.com/prometheus/client_golang)) = v0.8.0
Provides: bundled(golang(github.com/prometheus/client_model)) = fa8ad6fec33561be4280a8f0514318c79d7f6cb6
Provides: bundled(golang(github.com/prometheus/common)) = 195bde7883f7c39ea62b0d92ab7359b5327065cb
Provides: bundled(golang(github.com/prometheus/procfs)) = fcdb11ccb4389efb1b210b7ffb623ab71c5fdd60
Provides: bundled(golang(github.com/sirupsen/logrus)) = v1.0.0
Provides: bundled(golang(github.com/stevvooe/ttrpc)) = d4528379866b0ce7e9d71f3eb96f0582fc374577
Provides: bundled(golang(github.com/stretchr/testify)) = v1.1.4
Provides: bundled(golang(github.com/urfave/cli)) = 7bc6a0acffa589f415f88aca16cc1de5ffd66f9c
Provides: bundled(golang(golang.org/x/net)) = 7dcfb8076726a3fdd9353b6b8a1f1b6be6811bd6
Provides: bundled(golang(golang.org/x/sync)) = 450f422ab23cf9881c94e2db30cac0eb1b7cf80c
Provides: bundled(golang(golang.org/x/sys)) = 314a259e304ff91bd6985da2a7149bbf91237993
Provides: bundled(golang(golang.org/x/text)) = 19e51611da83d6be54ddafce4a4af510cb3e9ea4
Provides: bundled(golang(google.golang.org/genproto)) = d80a6e20e776b0b17a324d0ba1ab50a39c8e8944
Provides: bundled(golang(google.golang.org/grpc)) = v1.7.2


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
