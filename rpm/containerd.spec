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

%global major_minor %(echo "${RPM_VERSION%%.*}")

Name: containerd.io
Provides: containerd
# For some reason on rhel >= 8 if we "provide" runc then it makes this package unsearchable
%if %{undefined rhel} || 0%{?rhel} < 8
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
Source2: containerd.toml
Source3: runc
# container-selinux isn't a thing in suse flavors
%if %{undefined suse_version}
# amazonlinux2 doesn't have container-selinux either
%if "%{?dist}" != ".amzn2"
Requires: container-selinux >= 2:2.74
%endif
Requires: libseccomp
%else
# SUSE flavors do not have container-selinux,
# and libseccomp is named libseccomp2
Requires: libseccomp2
%endif
BuildRequires: make
BuildRequires: gcc
BuildRequires: systemd
BuildRequires: libseccomp-devel

# containerd 1.7.x now use Linux kernel headers for btrfs, so we only
# need this dependency when building older (1.5.x, 1.6.x) releases.
# TODO(thaJeztah): remove btrfs build-dependencies once containerd 1.6 reaches EOL.
%if "%{major_minor}" == "1.6" || "%{major_minor}" == "1.5"
%if %{undefined rhel} || 0%{?rhel} < 8
%if %{defined suse_version}
# SUSE flavors
BuildRequires: libbtrfs-devel
%else
# Fedora / others, and CentOS/RHEL < 8
BuildRequires: btrfs-progs-devel
%endif
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
GO111MODULE=auto make man

BUILDTAGS=""
%if %{defined rhel} && 0%{?rhel} >= 8
# btrfs support was removed in CentOS/RHEL 8
BUILDTAGS="${BUILDTAGS} no_btrfs"
%else
# TODO(thaJeztah): remove this block once 1.5.x and 1.6.x reach EOL.
%if %{defined rhel} && 0%{?rhel} >= 7 && "%{major_minor}" != "1.6" && "%{major_minor}" != "1.5"
# containerd 1.7.x now use linux kernel headers for btrfs, which is not
# provided by CentOS/RHEL 7, so don't build with btrfs for 1.7+.
BUILDTAGS="${BUILDTAGS} no_btrfs"
%endif
%endif

GO111MODULE=auto make -C /go/src/%{import_path} VERSION=%{getenv:VERSION} REVISION=%{getenv:REF} PACKAGE=%{getenv:PACKAGE} BUILDTAGS="${BUILDTAGS}"

# Remove containerd-stress, as we're not shipping it as part of the packages
rm -f bin/containerd-stress
bin/containerd --version
bin/ctr --version

GO111MODULE=auto make -C /go/src/github.com/opencontainers/runc BINDIR=%{_topdir}/BUILD/bin runc install


%install
cd %{_topdir}/BUILD
mkdir -p %{buildroot}%{_bindir}
install -D -m 0755 bin/* %{buildroot}%{_bindir}
install -D -m 0644 %{S:1} %{buildroot}%{_unitdir}/containerd.service
install -D -m 0644 %{S:2} %{buildroot}%{_sysconfdir}/containerd/config.toml

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
%{_sysconfdir}/containerd
%{_mandir}/man*/*
%config(noreplace) %{_sysconfdir}/containerd/config.toml


%changelog
* Fri Aug 25 2023 Josh Seba <jseba@cloudflare.com> - 1.7.5-3.1
- Update containerd binary to v1.7.5

* Fri Aug 25 2023 Josh Seba <jseba@cloudflare.com> - 1.7.4-3.1
- Update containerd binary to v1.7.4
- Update runc binary to v1.1.9
- Update Golang runtime to 1.20.7

* Fri Aug 25 2023 Josh Seba <jseba@cloudflare.com> - 1.7.3-3.1
- Update containerd binary to v1.7.3
- Update runc binary to v1.1.8
- Update Golang runtime to 1.20.6

* Sat Jul 29 2023 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.22-3.1
- update containerd binary to v1.6.22
- update runc binary to v1.1.8
- Update Golang runtime to 1.19.11

* Fri May 05 2023 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.21-3.1
- update containerd binary to v1.6.21
- update runc binary to v1.1.7
- Update Golang runtime to 1.19.9

* Thu Mar 30 2023 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.20-3.1
- update containerd binary to v1.6.20.
- update runc binary to v1.1.5, which includes fixes for CVE-2023-25809,
  CVE-2023-27561, and CVE-2023-28642.

* Thu Mar 23 2023 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.19-3.1
- Update containerd to v1.6.19
- Update Golang runtime to 1.19.7

* Thu Feb 16 2023 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.18-3.1
- update containerd binary to v1.6.18, which includes fixes for CVE-2023-25153
  and CVE-2023-25173.
- update Golang runtime to 1.19.6, which includes fixes for CVE-2022-41722,
  CVE-2022-41725, CVE-2022-41724, and CVE-2022-41723.

* Thu Feb 16 2023 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.17-3.1
- Update containerd to v1.6.17

* Mon Jan 30 2023 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.16-3.1
- Update containerd to v1.6.16
- Update Golang runtime to 1.18.10

* Mon Jan 09 2023 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.15-3.1
- Update containerd to v1.6.15

* Mon Dec 19 2022 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.14-3.1
- Update containerd to v1.6.14

* Thu Dec 15 2022 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.13-3.1
- Update containerd to v1.6.13

* Wed Dec 07 2022 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.12-3.1
- Update containerd to v1.6.12 to address CVE-2022-23471

* Tue Dec 06 2022 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.11-3.1
- Update containerd to v1.6.11
- Update Golang runtime to 1.18.9, which includes fixes for CVE-2022-41717,
  CVE-2022-41720, and CVE-2022-41720.

* Thu Nov 17 2022 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.10-3.1
- Update containerd to v1.6.10
- Update Golang runtime to 1.18.8

* Mon Oct 24 2022 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.9-3.1
- Update containerd to v1.6.9
- Update Golang runtime to 1.18.7

* Thu Aug 25 2022 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.8-3.1
- Update containerd to v1.6.8
- Update runc to v1.1.4

* Thu Aug 04 2022 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.7-3.1
- Update containerd to v1.6.7
- Update runc to v1.1.3
- Update Golang runtime to 1.17.13 to address CVE-2022-32189

* Mon Jun 06 2022 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.6-3.1
- Update containerd to v1.6.6 to address CVE-2022-31030

* Sat Jun 04 2022 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.5-3.1
- Update containerd to v1.6.5
- Update runc to v1.1.2
- Update Golang runtime to 1.17.11

* Wed May 04 2022 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.4-3.1
- Update containerd to v1.6.4

* Thu Apr 28 2022 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.3-3.1
- Update containerd to v1.6.3
- Update runc to v1.1.1
- Update Golang runtime to 1.17.9

* Sun Mar 27 2022 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.2-3.1
- Update containerd to v1.6.2
- Update runc to v1.1.0

* Wed Mar 23 2022 Sebastiaan van Stijn <thajeztah@docker.com> - 1.5.11-3.1
- Update containerd to v1.5.11 to address CVE-2022-24769

* Fri Mar 04 2022 Sebastiaan van Stijn <thajeztah@docker.com> - 1.5.10-3.1
- Update containerd to v1.5.10
- Update Golang runtime to 1.17.8
