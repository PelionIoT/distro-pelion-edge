%global goipath github.com/armPelionEdge/maestro
%global tag     v3.0.0
%global version v3.0.0
%gometa

Name:          maestro
Version:       3.0.0
Release:       1%{?dist}
Summary:       Pelion Edge systems management daemon

License:       Apache-2.0
URL:           %{gourl}
Source0:       %{gosource}

BuildRequires: m4 python27 gcc-c++ golang < 1.16 libunwind-devel
Requires(post): systemd-units
Requires(preun): systemd-units
Requires(postun): systemd-units

%description
Maestro is a replacement for a number of typical system utilities and
management programs, while providing cloud-connected systems management.
Maestro is designed specifically for cloud-connected embedded Linux computers,
with somewhat limited RAM and disk space, where file systems are often flash -
and would prefer less writing over time.

%prep
%goprep -k

%build
topdir=$(pwd)

mkdir -p "$topdir"/bin
%gobuild -o %{gobuilddir}/bin/%{name} %{goipath}/maestro

%install
install -vdm 0755                     %{buildroot}/var/log/pelion
install -vdm 0755                     %{buildroot}/var/lib/pelion/maestro
install -vdm 0755                     %{buildroot}/%{_bindir}
install -vpm 0755 %{gobuilddir}/bin/* %{buildroot}/%{_bindir}/

install -vdm 0755                               %{buildroot}/%{_sysconfdir}/pelion
install -vpm 0644 %{_filesdir}/relay-term-config.json  %{buildroot}/%{_sysconfdir}/pelion
install -vpm 0644 %{_filesdir}/pelion-base-config.yaml  %{buildroot}/%{_sysconfdir}/pelion

install -vdm 0755                               %{buildroot}/%{_unitdir}
install -vpm 0644 %{_filesdir}/maestro.service  %{buildroot}/%{_unitdir}

%files
%{_bindir}/*
/usr/lib/pelion
%{_unitdir}/maestro.service
%config %{_sysconfdir}/pelion/pelion-base-config.yaml
%config %{_sysconfdir}/pelion/relay-term-config.json

%dir
/var/lib/pelion/maestro
/var/log/pelion

%post
%systemd_post maestro.service

%preun
%systemd_preun maestro.service

%postun
%systemd_postun_with_restart maestro.service

%changelog
* Mon Nov 1 2021 Michael Ray <michael.ray@pelion.com> - 3.0.0-1
- Upgraded maestro rhel to v3.0.0
* Wed Jun 9 2021 Michael Ray <michael.ray@pelion.com> - 2.9.0-1
- Locked down version of all packages
* Wed May 20 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 0.0.1-1
- Initial release.
