%global goipath github.com/armPelionEdge/fog-core
%global commit  5251afa5cfac4de73c25d2d38e9fd799f3f80f91
%gometa

Name:           fog-core
Version:        0.0.1
Release:        1%{?dist}
Summary:        A message bus (golang)

License:        Apache-2.0
URL:            %{gourl}
Source0:        %{gosource}

%description
Provides a uniform interface between applications running on edge
gateways and devices connected to them. Fog-Core's core features
enable monitoring of device state, device control, device queries, and
device discovery all without applications needing to worry about where
a device is in the network. Fog-Core takes care of routing requests
and data where it needs to go so the application just needs to worry
about devices.

%prep
%goprep -k

%build
%gobuild -o %{gobuilddir}/bin/fog %{goipath}/cmd/fog

%install
install -vdm 0755                     %{buildroot}/%{_bindir}
install -vpm 0755 %{gobuilddir}/bin/* %{buildroot}/%{_bindir}/

%files
%{_bindir}/*

%changelog
* Wed May 20 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 0.0.1-1
- Initial release.
