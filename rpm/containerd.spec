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
# For some reason on rhel 8 if we "provide" runc then it makes this package unsearchable
%if 0%{!?el8:1}
Provides: runc
%endif

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
Source2: runc
# container-selinux isn't a thing in suse flavors
%if %{undefined suse_version}
# amazonlinux2 doesn't have container-selinux either
%if "%{?dist}" != ".amzn2"
Requires: container-selinux >= 2:2.74
%endif
Requires: libseccomp
%endif
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
if [ ! -d %{_topdir}/SOURCES/containerd ]; then
    # Copy over our source code from our gopath to our source directory
    cp -rf /go/src/%{import_path} %{_topdir}/SOURCES/containerd;
fi
# symlink the go source path to our build directory
ln -s /go/src/%{import_path} %{_topdir}/BUILD

if [ ! -d %{_topdir}/SOURCES/runc ]; then
    # Copy over our source code from our gopath to our source directory
    cp -rf /go/src/github.com/opencontainers/runc %{_topdir}/SOURCES/runc
fi
cd %{_topdir}/BUILD/


%build
cd %{_topdir}/BUILD
GO111MODULE=off make man

BUILDTAGS="seccomp selinux"
%if 1%{!?el8:1}
BUILDTAGS="${BUILDTAGS} no_btrfs"
%endif

GO111MODULE=off make -C /go/src/%{import_path} VERSION=%{getenv:VERSION} REVISION=%{getenv:REF} PACKAGE=%{getenv:PACKAGE} BUILDTAGS="${BUILDTAGS}"

# Remove containerd-stress, as we're not shipping it as part of the packages
rm -f bin/containerd-stress
bin/containerd --version
bin/ctr --version

GO111MODULE=off make -C /go/src/github.com/opencontainers/runc BINDIR=%{_topdir}/BUILD/bin BUILDTAGS='seccomp apparmor selinux %{runc_nokmem}' runc install


%install
cd %{_topdir}/BUILD
mkdir -p %{buildroot}%{_bindir}
install -D -m 0755 bin/* %{buildroot}%{_bindir}
install -D -m 0644 %{S:1} %{buildroot}%{_unitdir}/containerd.service

# install manpages, taking into account that not all sections may be present
for i in $(seq 1 8); do
    if ls man/*.${i} 1> /dev/null 2>&1; then
        install -d %{buildroot}%{_mandir}/man${i};
        install -p -m 644 man/*.${i} %{buildroot}%{_mandir}/man${i};
    fi
done

%post
%systemd_post containerd.service


%preun
%systemd_preun containerd.service


%postun
%systemd_postun_with_restart containerd.service


%files
%license LICENSE
%doc README.md
%{_bindir}/*
%{_unitdir}/containerd.service
%{_mandir}/man*/*


%changelog
* Mon Mar 08 2021 Wei Fu <fuweid89@gmail.com> - 1.4.4-3.1
- Update to containerd 1.4.4 to address CVE-2021-21334.

* Wed Mar 03 2021 Tibor Vass <tibor@docker.com> - 1.4.3-3.2
- Update runc to v1.0.0-rc93

* Wed Dec 02 2020 Sebastiaan van Stijn <thajeztah@docker.com> - 1.4.3-3.1
- Update to containerd 1.4.3 to address CVE-2020-15257.

* Thu Nov 26 2020 Sebastiaan van Stijn <thajeztah@docker.com> - 1.4.2-3.1
- Update to containerd 1.4.2

* Tue Oct 06 2020 Tibor Vass <tibor@docker.com> - 1.4.1-3.1
- Update to containerd 1.4.1
- Update Golang runtime to 1.13.15

* Wed Sep 09 2020 Sebastiaan van Stijn <github@gone.nl> - 1.3.7-3.1
- Update to containerd 1.3.7
- Update Golang runtime to 1.13.12.

* Fri May 01 2020 Sebastiaan van Stijn <thajeztah@docker.com> - 1.2.13-3.2
- Build packages for RHEL-7 on s390x, CentOS 8, and Fedora 32
- Add libseccomp as required dependency

* Mon Feb 17 2020 Sebastiaan van Stijn <thajeztah@docker.com> - 1.2.13-3.1
- Update to containerd 1.2.13, which fixes a regression introduced in v1.2.12
  that caused container/shim to hang on single core machines, and fixes an issue
  with blkio.
- Update Golang runtime to 1.12.17.

* Tue Feb 04 2020 Derek McGowan <derek@docker.com> - 1.2.12-3.1
- Update the runc vendor to v1.0.0-rc10 which includes a mitigation for
  CVE-2019-19921.
- Update the opencontainers/selinux which includes a mitigation for
  CVE-2019-16884.
- Update Golang runtime to 1.12.16, mitigating the CVE-2020-0601
  certificate verification bypass on Windows, and CVE-2020-7919,
  which only affects 32-bit architectures.
- A fix to prevent SIGSEGV when starting containerd-shim
- Fix to prevent high system load/CPU utilization with liveness and readiness
  probes
- Fix to prevent docker exec hanging if an earlier docker exec left a zombie
  process
- CRI: Update the gopkg.in/yaml.v2 vendor to v2.2.8 with a mitigation for
  CVE-2019-11253

* Fri Jan 24 2020 Sebastiaan van Stijn <thajeztah@docker.com> - 1.2.11-3.2
- Update Golang runtime to 1.12.15, which includes fixes in the net/http package
  and the runtime on ARM64

* Thu Jan 09 2020 Evan Hazlett <evan@docker.com> - 1.2.11-3.1
- Update the runc vendor to v1.0.0-rc9 which includes an additional
  mitigation for CVE-2019-16884
- Add local-fs.target to service file to fix corrupt image after unexpected
  host reboot
- Update Golang runtime to 1.12.13, which includes security fixes to the
  crypto/dsa package made in Go 1.12.11 (CVE-2019-17596), and fixes to the
  go command, runtime, syscall and net packages (Go 1.12.12)
- CRI: Fix shim delete error code to avoid unnecessary retries in the CRI plugin

* Mon Oct 07 2019 Eli Uriegas <eli.uriegas@docker.com> - 1.2.10-3.2
- build with Go 1.12.10

* Thu Sep 26 2019 Eli Uriegas <eli.uriegas@docker.com> - 1.2.10-3.1
- containerd 1.2.10 release
- Addresses CVE-2019-16884 (AppArmor bypass)
- Bump runc to 3e425f80a8c931f88e6d94a8c831b9d5aa481657 (1.0.0-rc8 + CVE-2019-16884)

* Fri Sep 06 2019 Eli Uriegas <eli.uriegas@docker.com> - 1.2.9-3.1
- containerd 1.2.9 release
- Addresses CVE-2019-9512 (Ping Flood), CVE-2019-9514 (Reset Flood), and CVE-2019-9515 (Settings Flood).

* Tue Aug 27 2019 Sebastiaan van Stijn <thajeztah@docker.com> - 1.2.8-3.1
- containerd 1.2.8 release
- build with Go 1.12.9

* Thu Aug 15 2019 Sebastiaan van Stijn <thajeztah@docker.com> - 1.2.6-3.5
- build with Go 1.11.13 (CVE-2019-9512, CVE-2019-9514)

* Tue Aug 13 2019 Eli Uriegas <eli.uriegas@docker.com> - 1.2.6-3.4
- Do not "Provides: runc" for RHEL 8

* Tue Jun 11 2019 Kir Kolyshkin <kolyshkin@gmail.com> - 1.2.6-3.3
- add requirement for container-selinux
- move runc binary to %_bindir

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
