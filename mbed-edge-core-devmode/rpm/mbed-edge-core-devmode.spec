%global forgeurl https://github.com/ARMmbed/mbed-edge
%global tag 0.16.1
%global version 0.16.1
%global debug_package %{nil}
%forgemeta

Name:           mbed-edge-core-devmode
Version:        0.16.1
Release:        1%{?dist}
Summary:        The core of Device Management Edge (developer version)
License:        Apache-2.0
URL:            %{forgeurl}
Source0:        %{forgesource}
Conflicts:      mbed-edge-core
BuildRequires:  cmake doxygen graphviz mosquitto-devel systemd systemd-rpm-macros
Requires(post): systemd-units
Requires(preun): systemd-units
Requires(postun): systemd-units

%description
Device Management Edge (from now on, just Edge) is a product that
enables you to connect a variety of devices to Device
Management. Examples of such devices are:

1. Existing legacy devices that use a protocol, such as BACNet, Modbus and
   Zigbee.
2. Non-IP based devices, such as Bluetooth LE.
3. Devices with a limited memory footprint that cannot host a full Device
   Management Client.

Edge lets you connect all these devices to Device Management, so you
can manage them and their resources remotely and locally. The Edge
Protocol Translator API is protocol agnostic, so anything your gateway
connects with can be connected to Edge. Use the Edge Management API to
create local management applications that can manage connected devices
with and without Device Management connectivity.

%prep
%setup -q %{forgesetupargs}

%build
cmake . -DDEVELOPER_MODE=ON -DFACTORY_MODE=ON -DBYOC_MODE=OFF \
        -DFOTA_ENABLE=OFF -DFIRMWARE_UPDATE=ON \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DMBED_CLOUD_DEV_UPDATE_ID=ON \
        -DMBED_CLOUD_CLIENT_CURL_DYNAMIC_LINK=OFF \
	-DPARSEC_TPM_SE_SUPPORT=OFF \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo
%make_build

%install
install -vdm 0755                                   %{buildroot}/var/lib/pelion/mbed/

install -vdm 0755                                   %{buildroot}/usr/lib/pelion/scripts/
install -vpm 0755 %{_filesdir}/arm*                 %{buildroot}/usr/lib/pelion/scripts/

install -vdm 0755                                   %{buildroot}/%{_bindir}
install -vpm 0755 bin/edge-core                     %{buildroot}/%{_bindir}

install -vdm 0755                                   %{buildroot}/%{_unitdir}
install -vpm 0755 %{_filesdir}/edge-core.service    %{buildroot}/%{_unitdir}

install -vdm 0755 %{buildroot}/%{_sysconfdir}/logrotate.d
install -vpm 0755 %{_filesdir}/edge-core.logrotate  %{buildroot}/%{_sysconfdir}/logrotate.d/edge-core

%files
%{_bindir}/edge-core
%{_unitdir}/edge-core.service
%{_sysconfdir}/logrotate.d/edge-core
/usr/lib/pelion/scripts/*

%dir
/var/lib/pelion/mbed/

%post
%systemd_post edge-core.service

%preun
%systemd_preun edge-core.service

%postun
%systemd_postun_with_restart edge-core.service

%changelog
* Mon Nov 15 2021 Nic Costa <nic.costa@pelion.com> - 0.16.1-1
- Upgraded mbed-edge-core 0.16.0 for Pelion Edge 2.3
* Mon Nov 15 2021 Nic Costa <nic.costa@pelion.com> - 0.15.0-1
- Upgraded mbed-edge-core 0.15.0 for Pelion Edge 2.2
* Wed Jun 9 2021 Michael Ray <michael.ray@pelion.com> - 0.13.0-1
- Locked down version of all packages
* Mon May 18 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 0.0.1-1
- Initial release.
