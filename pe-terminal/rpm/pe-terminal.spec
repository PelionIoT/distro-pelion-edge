%global goipath github.com/PelionIoT/pe-terminal
%global commit  5be41d5f8ae5a6e93643d0067533124e11d5d3a0
%gometa

Name:           pe-terminal
Version:        1.0.0
Release:        1%{?dist}
Summary:        Terminal-client for Pelion Edge

License:        Apache-2.0
URL:            %{gourl}
Source0:        %{gosource}

BuildRequires:  golang <= 1.15
Requires(post): systemd-units
Requires(preun): systemd-units
Requires(postun): systemd-units

%description
Terminal-client for Pelion Edge.

%prep
%goprep -k

%build
%gobuild -o %{gobuilddir}/bin/pe-terminal %{goipath}

%install
install -vdm 0755                                    %{buildroot}/%{_bindir}
install -vpm 0755 %{gobuilddir}/bin/*                %{buildroot}/%{_bindir}/

install -vdm 0755                                    %{buildroot}/%{_sysconfdir}/pelion
install -vpm 0644 %{_filesdir}/pe-terminal.conf.json %{buildroot}/%{_sysconfdir}/pelion

install -vdm 0755                                    %{buildroot}/%{_unitdir}
install -vpm 0755 %{_filesdir}/pe-terminal.service   %{buildroot}/%{_unitdir}

%files
%{_bindir}/*
%{_unitdir}/pe-terminal.service
%config %{_sysconfdir}/pelion/pe-terminal.conf.json

%post
%systemd_post pe-terminal.service

%preun
%systemd_preun pe-terminal.service

%postun
%systemd_postun_with_restart pe-terminal.service

%changelog
* Fri Sep 10 2021 Aditya Awasthi <aditya.awasthi@pelion.com> - 1.0.0
- Initial release.
