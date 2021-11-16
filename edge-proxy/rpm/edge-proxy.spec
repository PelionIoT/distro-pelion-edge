%global goipath github.com/PelionIoT/edge-proxy
%global tag     v1.0.0
%global version v1.0.0
%gometa

Name:           edge-proxy
Version:        1.0.0
Release:        1%{?dist}
Summary:        An HTTP proxy for Pelion Edge

License:        Apache-2.0
URL:            %{gourl}
Source0:        %{gosource}

BuildRequires:  golang-bin >= 1.15
Requires(post): systemd-units
Requires(preun): systemd-units
Requires(postun): systemd-units

%description
Provides a proxy for Pelion Edge components that routes traffic
through Edge Core.

%prep
%goprep -k

%build
%gobuild -o %{gobuilddir}/bin/edge-proxy %{goipath}/cmd/edge-proxy

%install
install -vdm 0755                                   %{buildroot}/%{_bindir}
install -vpm 0755 %{gobuilddir}/bin/*               %{buildroot}/%{_bindir}/
install -vpm 0755 %{_filesdir}/launch-edge-proxy.sh %{buildroot}/%{_bindir}

install -vdm 0755                                   %{buildroot}/%{_sysconfdir}/pelion
install -vpm 0644 %{_filesdir}/edge-proxy.conf.json %{buildroot}/%{_sysconfdir}/pelion

install -vdm 0755                                   %{buildroot}/%{_unitdir}
install -vpm 0755 %{_filesdir}/edge-proxy.service   %{buildroot}/%{_unitdir}

%files
%{_bindir}/*
%{_unitdir}/edge-proxy.service
%config %{_sysconfdir}/pelion/edge-proxy.conf.json

%post
%systemd_post edge-proxy.service

%preun
%systemd_preun edge-proxy.service

%postun
%systemd_postun_with_restart edge-proxy.service

%changelog
* Tue Nov 16 2021 Nic Costa <nic.costa@pelion.com> - 1.0.0-1
- Adds proxy-only mode which allows edge-proxy to run HTTP and HTTPS servers
* Wed Jun 9 2021 Michael Ray <michael.ray@pelion.com> - 0.9.0-1
- Adds proxy-only mode which allows edge-proxy to run HTTP and HTTPS servers
* Wed Jun 9 2021 Michael Ray <michael.ray@pelion.com> - 0.9.0-1
- Locked down version of all packages
* Wed May 20 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 0.0.1-1
- Initial release.
