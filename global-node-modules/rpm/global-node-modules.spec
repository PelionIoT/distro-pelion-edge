%global debug_package %{nil}
%global tag     v1.0.0
%global version v1.0.0
%global __requires_exclude bin/coffee$

Name:           global-node-modules
Version:        1.0.0
Release:        1%{?dist}
Summary:        A collection of Node.js modules used by Pelion Edge

License:        Apache-2.0
URL:            https://github.com/PelionIoT/edge-node-modules

# The source for this package was generated via
# https://github.com/PelionIoT/ubuntu-pelion-edge-internal
Source0:        edge-node-modules.tar.gz

# TODO: pe-nodejs-dev for build
BuildRequires:  pe-nodejs python2 systemd-devel
Requires:       pe-nodejs
Requires(post): systemd-units
Requires(preun): systemd-units
Requires(postun): systemd-units

%description
Node.js modules used by different Pelion Edge components.

%prep
%setup -q -n edge-node-modules

%build
npm rebuild --production
rm -f rsmi/bin/cc2530prog-x86
rm -f rsmi/bin/slipcomms-x86

%install
%global pelibdir    /usr/lib/pelion
%global devicejsdir %{pelibdir}/devicejs-core-modules
%global wigwagdir   %{pelibdir}/wigwag-core-modules

install -vdm 0755 %{buildroot}/%{devicejsdir}
install -vdm 0755 %{buildroot}/%{wigwagdir}

cp -r package.json rsmi zigbeeHA node_modules maestroRunner \
   core-interfaces bluetoothlowenergy %{buildroot}/%{devicejsdir}

cp -r DevStateManager LEDController RelayStatsSender VirtualDeviceDriver \
   onsite-enterprise-server relay-term %{buildroot}/%{wigwagdir}

install -vdm 0755                               %{buildroot}/%{_unitdir}
install -vpm 0644 %{_filesdir}/pelion-relay-term.service  %{buildroot}/%{_unitdir}

%files
%{devicejsdir}/*
%{wigwagdir}/*
%{_unitdir}/pelion-relay-term.service

%post
%systemd_post pelion-relay-term.service

%preun
%systemd_preun pelion-relay-term.service

%postun
%systemd_postun_with_restart pelion-relay-term.service

%changelog
* Wed Jun 9 2021 Michael Ray <michael.ray@pelion.com> - 1.0.0-1
- Locked down version of all packages
* Wed May 20 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 0.0.1-1
- Initial release.
