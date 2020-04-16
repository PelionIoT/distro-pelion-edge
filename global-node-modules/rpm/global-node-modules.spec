%global debug_package %{nil}
%global __requires_exclude bin/coffee$

Name:           global-node-modules
Version:        0.0.1
Release:        1%{?dist}
Summary:        A collection of Node.js modules used by Pelion Edge

License:        Apache-2.0
URL:            https://github.com/armPelionEdge/edge-node-modules

# The source for this package was generated via
# https://github.com/armPelionEdge/ubuntu-pelion-edge-internal
Source0:        edge-node-modules.tar.gz

BuildRequires:  nodejs = 2:8.11.4-1nodesource
Requires:       pe-nodejs

%description
Node.js modules used by different Pelion Edge components.

%prep
%setup -q -n edge-node-modules

%build
npm rebuild --production
rm -f rsmi/bin/cc2530prog-x86
rm -f rsmi/bin/slipcomms-x86

%install
%global pelibdir    %{_libdir}/pelion
%global devicejsdir %{pelibdir}/devicejs-core-modules
%global wigwagdir   %{pelibdir}/wigwag-core-modules

install -vdm 0755 %{buildroot}/%{devicejsdir}
install -vdm 0755 %{buildroot}/%{wigwagdir}

cp -r package.json rsmi zigbeeHA node_modules maestroRunner \
   core-interfaces bluetoothlowenergy %{buildroot}/%{devicejsdir}

cp -r DevStateManager LEDController RelayStatsSender VirtualDeviceDriver \
   onsite-enterprise-server relay-term %{buildroot}/%{wigwagdir}

%files
%{devicejsdir}/*
%{wigwagdir}/*

%changelog
* Wed May 20 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 0.0.1-1
- Initial release.
