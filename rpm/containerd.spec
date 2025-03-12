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
License: Apache-2.0
URL: https://containerd.io
Source0: containerd
Source1: containerd.service
Source2: containerd.toml
Source3: runc
# container-selinux isn't a thing in suse flavors
%if %{undefined suse_version}
# amazonlinux2 doesn't have container-selinux either
%if "%{?dist}" != ".amzn2"
Requires: container-selinux
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

%{?systemd_requires}

%description
containerd is an industry-standard container runtime with an emphasis on
simplicity, robustness and portability. It is available as a daemon for Linux
and Windows, which can manage the complete container lifecycle of its host
system: image transfer and storage, container execution and supervision,
low-level storage and network attachments, etc.


%prep
rm -rf %{_builddir}
if [ ! -d %{_sourcedir}/containerd ]; then
    # Copy over our source code from our gopath to our source directory
    cp -rf /go/src/%{import_path} %{_sourcedir}/containerd;
fi
# symlink the go source path to our build directory
ln -s /go/src/%{import_path} %{_builddir}

if [ ! -d %{_sourcedir}/runc ]; then
    # Copy over our source code from our gopath to our source directory
    cp -rf /go/src/github.com/opencontainers/runc %{_sourcedir}/runc
fi
cd %{_builddir}


%build
cd %{_builddir}
make man

BUILDTAGS=""

# TODO(thaJeztah): can we remove the version compare, or would that exclude other RHEL derivatives (Fedora, etc)?
%if %{defined rhel} && 0%{?rhel} >= 7
# btrfs support was removed in CentOS/RHEL 8, and containerd 1.7+ uses
# linux kernel headers for btrfs, which are not provided by CentOS/RHEL 7
# so build without btrfs support for any CentOS/RHEL version.
BUILDTAGS="${BUILDTAGS} no_btrfs"
%endif

make -C /go/src/%{import_path} VERSION=%{getenv:VERSION} REVISION=%{getenv:REF} PACKAGE=%{getenv:PACKAGE} BUILDTAGS="${BUILDTAGS}"

# Remove containerd-stress, as we're not shipping it as part of the packages
rm -f bin/containerd-stress
bin/containerd --version
bin/ctr --version

# Unset the VERSION variable as it's meant for containerd's version, not runc.
env -u VERSION make -C /go/src/github.com/opencontainers/runc BINDIR=%{_builddir}/bin runc install


%install
cd %{_builddir}
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
* Wed Mar 12 2025 Paweł Gronowski <pawel.gronowski@docker.com> - 1.7.26-3.1
- Update containerd binary to v1.7.26
- Update runc binary to v1.2.5

* Fri Jan 10 2025 Paweł Gronowski <pawel.gronowski@docker.com> - 1.7.25-3.1
- Update containerd binary to v1.7.25
- Update runc binary to v1.2.4
- Update the license fields to use the recommented SPDX identifier

* Thu Nov 21 2024 Sebastiaan van Stijn <thajeztah@docker.com> - 1.7.24-3.1
- Update containerd binary to v1.7.24
- Update systemd unit to start containerd service after dbus.service
- Update runc binary to v1.2.2

* Mon Nov 11 2024 Sebastiaan van Stijn <thajeztah@docker.com> - 1.7.23-3.1
- Update containerd binary to v1.7.23
- Update Golang runtime to 1.22.9

* Tue Sep 10 2024 Sebastiaan van Stijn <thajeztah@docker.com> - 1.7.22-3.1
- Update containerd binary to v1.7.22
- Update runc binary to v1.1.14
- Update Golang runtime to 1.22.7

* Tue Aug 27 2024 Paweł Gronowski <pawel.gronowski@docker.com> - 1.7.21-3.1
- Update containerd binary to v1.7.21
- Update Golang runtime to 1.22.6

* Thu Aug 08 2024 Sebastiaan van Stijn <thajeztah@docker.com> - 1.7.20-3.1
- Update containerd binary to v1.7.20
- Fix runc binary showing the incorrect version.

* Tue Jul 16 2024 Sebastiaan van Stijn <thajeztah@docker.com> - 1.7.19-3.1
- Update containerd binary to v1.7.19
- Update Golang runtime to 1.21.12, which includes a fix for CVE-2024-24791.

* Tue Jun 18 2024 Sebastiaan van Stijn <thajeztah@docker.com> - 1.7.18-3.1
- Update containerd binary to v1.7.18
- Update runc binary to v1.1.13

* Tue Jun 04 2024 Sebastiaan van Stijn <thajeztah@docker.com> - 1.6.33-3.1
- Update containerd binary to v1.6.33
- Update Golang runtime to 1.21.11, which includes fixes for CVE-2024-24789, CVE-2024-24790.
