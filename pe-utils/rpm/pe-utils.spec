%global forgeurl https://github.com/armPelionEdge/pe-utils
%global tag		2.0.7
%global version 2.0.7
%forgemeta
%global debug_package %{nil}

Name:           pe-utils
Version:        2.0.7
Release:        1%{?dist}
Summary:        Pelion utilities

License:        Apache-2.0
URL:            %{forgeurl}
Source0:        %{forgesource}

BuildRequires: pe-nodejs
Requires:       pe-nodejs
Requires:       curl
Requires:       jq
Requires:       openssl

Requires(post): systemd-units
Requires(preun): systemd-units
Requires(postun): systemd-units

%global pelibdir    /usr/lib/pelion

%description
Utilities and light-weight programs for Pelion Edge.

%prep
%forgesetup

%build

%install
install -vdm 0755 %{buildroot}/%{pelibdir}
install -vdm 0755 %{buildroot}/%{_bindir}
install -vpm 0755 identity-tools/generate-identity.sh %{buildroot}/%{pelibdir}
install -vpm 0755 %{_filesdir}/launch-wait-for-pelion-identity.sh	%{buildroot}/%{pelibdir}
cp -a identity-tools/developer_identity %{buildroot}/%{pelibdir}

install -vdm 0755													%{buildroot}/%{_unitdir}
install -vpm 0755 %{_filesdir}/wait-for-pelion-identity.service		%{buildroot}/%{_unitdir}

%files
%{pelibdir}/generate-identity.sh
%{pelibdir}/launch-wait-for-pelion-identity.sh
%{pelibdir}/developer_identity
%{_unitdir}/wait-for-pelion-identity.service

%post
%systemd_post edge-core.service

%preun
%systemd_preun edge-core.service

%postun
%systemd_postun_with_restart edge-core.service

%changelog
* Wed Jun 9 2021 Michael Ray <michael.ray@pelion.com> - 2.0.7-1
- Locked down version of all packages
* Thu Feb 11 2021 Krzysztof Bembnista <krzysztof.bembnista@globallogic.com> - 2.0.4-1
- version bump. Scripts does not use .ssl directory anumore
* Mon May 25 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 0.0.1-1
- Initial release.
