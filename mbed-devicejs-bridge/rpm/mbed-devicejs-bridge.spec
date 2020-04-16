%global debug_package %{nil}

# brp-mangle-shebangs screws up relative paths to the CoffeeScript
# interpreter, which leads to installation errors saying that nothing
# provides the CoffeeScript executable.
%global __brp_mangle_shebangs_exclude \\./node_modules/\\.bin/coffee$

Name:           mbed-devicejs-bridge
Version:        0.0.1
Release:        1%{?dist}
Summary:        Bridge interface from devicejs to edge-core

License:        Apache-2.0
URL:            https://github.com/armPelionEdge/mbed-devicejs-bridge

# The source for this package was generated via
# https://github.com/armPelionEdge/ubuntu-pelion-edge-internal
Source0:        mbed-devicejs-bridge.tar.gz

BuildRequires:  nodejs = 2:8.11.4-1nodesource
Requires:       pe-nodejs

%description
Bridging software, which exposes devices in deviceJS to mbed, and vice versa.
The mbed-devicejs-bridge software should be installed on all Arm mbed branded
gateways.

%prep
%setup -q -n mbed-devicejs-bridge

%build

%install
%global mbeddir    %{_libdir}/pelion/mbed

install -vdm 0755          %{buildroot}/%{mbeddir}
cp -a mbed-devicejs-bridge %{buildroot}/%{mbeddir}
cp -a mbed-edge-websocket  %{buildroot}/%{mbeddir}

%files
%{mbeddir}/mbed-devicejs-bridge
%{mbeddir}/mbed-edge-websocket

%changelog
* Tue May 26 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 0.0.1-1
- Initial release.
