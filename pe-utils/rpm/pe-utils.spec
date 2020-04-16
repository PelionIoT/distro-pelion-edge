%global forgeurl https://github.com/armPelionEdge/pe-utils
%global commit   ffe2cd18c4f5948c78223974bfbdfe04779e9a9e
%forgemeta
%global debug_package %{nil}

Name:           pe-utils
Version:        0.0.1
Release:        1%{?dist}
Summary:        Pelion utilities

License:        Apache-2.0
URL:            %{forgeurl}
Source0:        %{forgesource}

Requires:       pe-nodejs
Requires:       curl
Requires:       jq
Requires:       openssl

%description
Utilities and light-weight programs for Pelion Edge.

%prep
%forgesetup

%build

%install
install -vdm 0755 %{buildroot}/%{_libdir}/pelion
install -vdm 0755 %{buildroot}/%{_bindir}
install -vpm 0755 identity-tools/generate-identity.sh %{buildroot}/%{_bindir}
cp -a identity-tools/developer_identity %{buildroot}/%{_libdir}/pelion/

%files
%{_bindir}/generate-identity.sh
%{_libdir}/pelion/developer_identity

%changelog
* Mon May 25 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 0.0.1-1
- Initial release.
