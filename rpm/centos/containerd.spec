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

%if ! 0%{?gobuild:1}
%define gobuild(o:) go build -ldflags "${LDFLAGS:-} -B 0x$(head -c20 /dev/urandom|od -An -tx1|tr -d ' \\n')" -a -v -x %{?**};
%endif

%global import_path github.com/containerd/containerd

Name: containerd
BuildArch: x86_64
Version: %{_version} 
%global commit  %{_gitcommit}
%global tag v%{version}
Release: 1%{?dist}
Summary: An industry-standard container runtime
License: ASL 2.0
URL: https://containerd.io
Source0: containerd.tar.gz
Source1: containerd.service
Source2: containerd.toml
ExclusiveArch: x86_64
ExclusiveArch: aarch64
ExclusiveArch: ppc64le
ExclusiveArch: s390x
#ExclusiveArch: %{go_arches}
BuildRequires: systemd
#%{?go_compiler:BuildRequires: compiler(go-compilers)}
#BuildRequires: golang >= 1.9
BuildRequires: btrfs-progs-devel
%{?systemd_requires}
# https://github.com/containerd/containerd/issues/1508#issuecomment-335566293
Requires: runc >= 1.0.0

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
#rpm -e $(rpm -qa | grep -i golang)
curl -fSL "https://golang.org/dl/go1.9.5.linux-amd64.tar.gz" | tar xzC /usr/local
export GOPATH=$(pwd):/%{gopath}
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
