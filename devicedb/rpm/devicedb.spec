%global goipath github.com/armPelionEdge/devicedb
%global commit  66859c16080c98dc4af5e75f3c093d0c9387e9b3
%gometa

Name:           devicedb
Version:        0.0.1
Release:        1%{?dist}
Summary:        A key-value store for Pelion Edge

License:        Apache-2.0
URL:            %{gourl}
Source0:        %{gosource}

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

%files
%{_bindir}/*

%changelog
* Wed May 20 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 0.0.1-1
- Initial release.
