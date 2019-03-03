BuildRoot: /root/.tmp/rpmrebuild.95/work/root
AutoProv: no
%undefine __find_provides
AutoReq: no
%undefine __find_requires

%undefine __check_files
%undefine __find_prereq
%undefine __find_conflicts
%undefine __find_obsoletes

# Build policy set to nothing
%define __spec_install_post %{nil}
# For rmp-4.1
%define __missing_doc_files_terminate_build 0

%bcond_without ctr
%bcond_with debug

%if %{with debug}
%global _dwz_low_mem_die_limit 0
%else
%global debug_package %{nil}
%endif

%define SHA256SUM0 08f057ece7e518b14cce2e9737228a5a899a7b58b78248a03e02f4a6c079eeaf
%global import_path github.com/containerd/containerd
%global gopath %{getenv:GOPATH}

Name: containerd.io
Provides: containerd
Obsoletes: containerd
Conflicts: containerd
Version: %{getenv:RPM_VERSION}
Release: %{getenv:RPM_RELEASE_VERSION}%{?dist}
Summary: An industry-standard container runtime
License: ASL 2.0
URL: https://containerd.io
Source0: containerd
Source1: containerd.service
Source2: containerd.toml
Source3: containerd-offline-installer
BuildRequires: make
BuildRequires: gcc
BuildRequires: systemd
BuildRequires: libseccomp-devel

%if 0%{?suse_version}
BuildRequires: libbtrfs-devel
%else
BuildRequires: btrfs-progs-devel
BuildRequires: golang-github-cpuguy83-go-md2man
%endif

%{?systemd_requires}

%description
containerd is an industry-standard container runtime with an emphasis on
simplicity, robustness and portability. It is available as a daemon for Linux
and Windows, which can manage the complete container lifecycle of its host
system: image transfer and storage, container execution and supervision,
low-level storage and network attachments, etc.


%prep
rm -rf %{_topdir}/BUILD/
# Copy over our source code from our gopath to our source directory
cp -rf /go/src/%{import_path} %{_topdir}/SOURCES/containerd
cp -rf /go/src/github.com/crosbymichael/offline-install %{_topdir}/SOURCES/containerd-offline-installer
# symlink the go source path to our build directory
ln -s /go/src/%{import_path} %{_topdir}/BUILD
cd %{_topdir}/BUILD/


%build
cd %{_topdir}/BUILD
make man

pushd /go/src/%{import_path}
%define make_containerd(o:) make VERSION=%{getenv:VERSION} REVISION=%{getenv:REF} %{?**};
%make_containerd bin/containerd
/go/src/%{import_path}/bin/containerd --version
%make_containerd bin/containerd-shim
%make_containerd bin/ctr
/go/src/%{import_path}/bin/ctr --version
popd

pushd /go/src/github.com/crosbymichael/offline-install
go build -o %{_topdir}/BUILD/bin/containerd-offline-installer main.go
popd

%install
cd %{_topdir}/BUILD
install -D -m 0755 bin/containerd %{buildroot}%{_bindir}/containerd
install -D -m 0755 bin/containerd-shim %{buildroot}%{_bindir}/containerd-shim
install -D -m 0755 bin/containerd-offline-installer %{buildroot}%{_libexecdir}/containerd-offline-installer
install -D -m 0755 bin/ctr %{buildroot}%{_bindir}/ctr
install -D -m 0644 %{_topdir}/SOURCES/runc.tar %{buildroot}%{_sharedstatedir}/containerd-offline-installer/runc.tar
install -D -m 0644 %{S:1} %{buildroot}%{_unitdir}/containerd.service
install -D -m 0644 %{S:2} %{buildroot}%{_sysconfdir}/containerd/config.toml

# install manpages
install -d %{buildroot}%{_mandir}/man1
install -p -m 644 man/*.1 $RPM_BUILD_ROOT/%{_mandir}/man1
install -d %{buildroot}%{_mandir}/man5
install -p -m 644 man/*.5 $RPM_BUILD_ROOT/%{_mandir}/man5

%post
%systemd_post containerd.service


%preun
%systemd_preun containerd.service


%postun
%systemd_postun_with_restart containerd.service


%files
%license LICENSE
%doc README.md
%{_bindir}/containerd
%{_bindir}/containerd-shim
%{_libexecdir}/containerd-offline-installer
%{?with_ctr:%{_bindir}/ctr}
%{_unitdir}/containerd.service
%{_sysconfdir}/containerd
%{_sharedstatedir}/containerd-offline-installer/runc.tar
/%{_mandir}/man1/*
/%{_mandir}/man5/*
%config(noreplace) %{_sysconfdir}/containerd/config.toml


%changelog
* Tue Aug 28 2018 Andrew Hsu <andrewhsu@docker.com> - 1.2.0-1.0.beta.2-1
- containerd 1.2.0 beta.2

* Thu Aug 16 2018 Eli Uriegas <eli.uriegas@docker.com> - 1.2.0-1.0.beta.0-1
- Intial release
