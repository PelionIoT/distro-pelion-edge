%global forgeurl https://github.com/armPelionEdge/devicejs-ng
%global commit   5aa4eabdfac119a1f837c5ff2589d8104bc66997
%forgemeta
%global debug_package %{nil}

%global __brp_mangle_shebangs_exclude_from /node_modules/

Name:           devicejs-ng
Version:        0.0.1
Release:        1%{?dist}
Summary:        A message bus (nodejs)

License:        Apache-2.0
URL:            %{forgeurl}
Source0:        %{forgesource}

BuildRequires:  nodejs = 2:8.11.4-1nodesource
Requires:       pe-nodejs

%description
Provides a uniform interface between applications running on edge
gateways and devices connected to them.

%prep
%setup -q %{forgesetupargs}

%build
npm rebuild --production

%install
install -vdm 0755 %{buildroot}/%{_libdir}/pelion/devicejs-ng

cp -a \
    bin build.sh deps docs index.js install.sh LICENSE node_modules \
    package.json src test uninstall.sh yuidoc.json \
    %{buildroot}/%{_libdir}/pelion/devicejs-ng/

%files
%{_libdir}/pelion/devicejs-ng

%changelog
* Wed May 20 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 0.0.1-1
- Initial release.
