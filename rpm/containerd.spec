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
%global runc_nokmem %{getenv:RUNC_NOKMEM}

Name: containerd.io
Provides: containerd
Provides: runc

# Obsolete packages
Obsoletes: containerd
Obsoletes: runc

# Conflicting packages
Conflicts: containerd
Conflicts: runc

Version: %{getenv:RPM_VERSION}
Release: %{getenv:RPM_RELEASE_VERSION}%{?dist}
Summary: An industry-standard container runtime
License: ASL 2.0
URL: https://containerd.io
Source0: containerd
Source1: containerd.service
Source2: containerd.toml
Source3: runc
BuildRequires: make
BuildRequires: gcc
BuildRequires: systemd
BuildRequires: libseccomp-devel

# Should only return true if `el8` (rhel8) is NOT defined
%if 0%{!?el8:1}
%if 0%{?suse_version}
BuildRequires: libbtrfs-devel
%else
BuildRequires: btrfs-progs-devel
%endif
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
# symlink the go source path to our build directory
ln -s /go/src/%{import_path} %{_topdir}/BUILD
# Copy over our source code from our gopath to our source directory
cp -rf /go/src/github.com/opencontainers/runc %{_topdir}/SOURCES/runc
cd %{_topdir}/BUILD/


%build
cd %{_topdir}/BUILD
make man

pushd /go/src/%{import_path}
%define make_containerd(o:) make VERSION=%{getenv:VERSION} REVISION=%{getenv:REF} PACKAGE=%{getenv:PACKAGE} %{?**};
%make_containerd bin/containerd
/go/src/%{import_path}/bin/containerd --version
%make_containerd bin/containerd-shim
%make_containerd bin/ctr
/go/src/%{import_path}/bin/ctr --version
popd

pushd /go/src/github.com/opencontainers/runc
make BUILDTAGS='seccomp apparmor selinux %{runc_nokmem}' runc
popd


%install
cd %{_topdir}/BUILD
install -D -m 0755 bin/containerd %{buildroot}%{_bindir}/containerd
install -D -m 0755 bin/containerd-shim %{buildroot}%{_bindir}/containerd-shim
install -D -m 0755 bin/ctr %{buildroot}%{_bindir}/ctr
install -D -m 0644 %{S:1} %{buildroot}%{_unitdir}/containerd.service
install -D -m 0644 %{S:2} %{buildroot}%{_sysconfdir}/containerd/config.toml
install -D -m 0755 /go/src/github.com/opencontainers/runc/runc %{buildroot}%{_sbindir}/runc

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
%{?with_ctr:%{_bindir}/ctr}
%{_sbindir}/runc
%{_unitdir}/containerd.service
%{_sysconfdir}/containerd
/%{_mandir}/man1/*
/%{_mandir}/man5/*
%config(noreplace) %{_sysconfdir}/containerd/config.toml


%changelog
* Fri Apr 26 2019 Sebastiaan van Stijn <thajeztah@docker.com> - 1.2.6-3.2
- update runc to v1.0.0-rc8

* Tue Apr 09 2019 Sebastiaan van Stijn <thajeztah@docker.com> - 1.2.6-3.1
- containerd 1.2.6 release
- update runc to 029124da7af7360afa781a0234d1b083550f797c
- build with Go 1.11.8

* Thu Mar 14 2019  Sebastiaan van Stijn <thajeztah@docker.com> - 1.2.5-3.1
- containerd 1.2.5 release
- update runc to 2b18fe1d885ee5083ef9f0838fee39b62d653e30
- build with Go 1.11.5

* Fri Feb 15 2019 Sebastiaan van Stijn <thajeztah@docker.com> - 1.2.4-3.1
- containerd 1.2.4 release
- update runc to 6635b4f0c6af3810594d2770f662f34ddc15b40d

* Thu Jan 31 2019 Eli Uriegas <eli.uriegas@docker.com> - 1.2.2-3.3
- [runc -> 09c8266] nsenter: clone /proc/self/exe to avoid exposing
  host binary to container (CVE-2019-5736)

* Fri Jan 18 2019 Eli Uriegas <eli.uriegas@docker.com> - 1.2.2-3.2
- update runc to f7491ef134a6c41f3a99b0b539835d2472d17012

* Tue Jan 08 2019 Andrew Hsu <andrewhsu@docker.com> - 1.2.2-3.1
- containerd 1.2.2 release

* Thu Dec 06 2018 Andrew Hsu <andrewhsu@docker.com> - 1.2.1-3.1
- containerd 1.2.1 release
- update runc to 96ec2177ae841256168fcf76954f7177af9446eb

* Tue Nov 27 2018  Sebastiaan van Stijn <thajeztah@docker.com> - 1.2.1-2.0.rc.0.1
- containerd 1.2.1-rc.0 release
- update runc to 10d38b660a77168360df3522881e2dc2be5056bd

* Mon Nov 05 2018 Eli Uriegas <eli.uriegas@docker.com> - 1.2.0-3.1
- containerd 1.2.0 release

* Tue Oct 16 2018 Eli Uriegas <eli.uriegas@docker.com> - 1.2.0-2.2.rc.2.1
- containerd 1.2.0-rc.2 release

* Fri Oct 05 2018 Eli Uriegas <eli.uriegas@docker.com> - 1.2.0-2.1.rc.1.1
- containerd 1.2.0-rc.1 release
- Set Tasks=infinity in the systemd service file

* Tue Sep 25 2018 Eli Uriegas <eli.uriegas@docker.com> - 1.2.0-2.0.rc.0.1
- containerd 1.2.0-rc.0 release

* Wed Sep 05 2018 Eli Uriegas <eli.uriegas@docker.com> - 1.2.0-1.2.beta.2.2
- Hardcoded paths for libexec and var lib considering the macros are different on SUSE based distributions
- Removed offline installer for runc, package as a binary instead

* Tue Aug 28 2018 Andrew Hsu <andrewhsu@docker.com> - 1.2.0-1.2.beta.2.1
- containerd 1.2.0 beta.2

* Thu Aug 16 2018 Eli Uriegas <eli.uriegas@docker.com> - 1.2.0-1.0.beta.0-1
- Intial release
