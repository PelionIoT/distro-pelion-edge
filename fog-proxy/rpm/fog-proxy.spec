%global goipath github.com/armPelionEdge/fog-proxy
%global commit  fe33b2bc2570da514326937597d84343bf4febe6
%gometa

Name:           fog-proxy
Version:        0.0.1
Release:        1%{?dist}
Summary:        An HTTP proxy for Pelion Edge

License:        Apache-2.0
URL:            %{gourl}
Source0:        %{gosource}

%description
Provides a proxy for Pelion Edge components that routes traffic
through Edge Core.

%prep
%goprep -k

%build
%gobuild -o %{gobuilddir}/bin/fp-edge %{goipath}/cmd/fp-edge

%install
install -vdm 0755                     %{buildroot}/%{_bindir}
install -vpm 0755 %{gobuilddir}/bin/* %{buildroot}/%{_bindir}/

%files
%{_bindir}/*

%changelog
* Wed May 20 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 0.0.1-1
- Initial release.
