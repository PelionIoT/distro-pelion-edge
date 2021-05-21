%global goipath github.com/armPelionEdge/devicedb
%global commit  d24df289ab24a035ebf64d2ed27a2d531a2319da
%gometa

Name:           devicedb
Version:        0.0.1
Release:        1%{?dist}
Summary:        A key-value store for Pelion Edge

License:        Apache-2.0
URL:            %{gourl}
Source0:        %{gosource}

BuildRequires:  golang < 1.15
Requires(post): systemd-units
Requires(preun): systemd-units
Requires(postun): systemd-units

%description
DeviceDB is a key value store that runs both on IoT gateways and in
the cloud to allow configuration and state data to be easily shared
between applications running in the cloud and applications running on
the gateway.

%prep
%goprep -k

%build
%gobuild -o %{gobuilddir}/bin/%{name} %{goipath}

%install
install -vdm 0755                     %{buildroot}/%{_bindir}
install -vpm 0755 %{gobuilddir}/bin/* %{buildroot}/%{_bindir}/
install -vdm 0755                     %{buildroot}/%{_unitdir}
install -vpm 0755 %{_filesdir}/devicedb.service   %{buildroot}/%{_unitdir}

%files
%{_bindir}/*
%{_unitdir}/devicedb.service

%post
%systemd_post devicedb.service

%preun
%systemd_preun devicedb.service

%postun
%systemd_postun_with_restart devicedb.service

%changelog
* Wed May 20 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 0.0.1-1
- Initial release.
