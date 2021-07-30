%global forgeurl https://github.com/PelionIoT/mbed-edge
%global tag     0.18.0
%global version 0.18.0
%global debug_package %{nil}
%forgemeta

Name:           mbed-edge-core
Version:        0.18.0
Release:        1%{?dist}
Summary:        The core of Device Management Edge
License:        Apache-2.0
URL:            %{forgeurl}
Source0:        %{forgesource}
Conflicts:      mbed-edge-core-devmode
BuildRequires:  cmake doxygen graphviz mosquitto-devel
Requires(post): systemd-units
Requires(preun): systemd-units
Requires(postun): systemd-units
Patch0: 0001-Add-PAL-Proxy-module-using-HTTP.patch
Patch1: 0002-Increasing-Path-Size.patch
Patch2: 0005-Read-platform-version-files-into-LWM2M-resources.patch
Patch3: 0010-Add-network-proxy-support.patch
Patch4: 0011-Call-a-script-on-factory-reset.patch
Patch5: 0012-add-API-to-set-a-resource-value-without-forced-text-.patch
Patch6: 0013-add-stubs-for-gateway-statistics-resources.patch
Patch7: 0014-add-cpu-usage-3-0-3320.patch
Patch8: 0015-add-cpu-temp-3-0-3303.patch
Patch9: 0016-add-RAM-total-3-0-3322-and-RAM-free-3-0-3321.patch
Patch10: 0017-add-disk-free-3-0-3323-and-disk-total-3-0-3324.patch
Patch11: 0020-edge-tool-pin-cryptography-to-3.3.patch
Patch12: 0021-edge-tool-fix-setup.py-to-install-the-edge_tool.py-s.patch


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
%patch0 -p1
%patch1 -p1
%patch2 -p1
%patch3 -p1
%patch4 -p1
%patch5 -p1
%patch6 -p1
%patch7 -p1
%patch8 -p1
%patch9 -p1
%patch10 -p1
%patch11 -p1
%patch12 -p1

%build
cmake . -DBYOC_MODE=ON -DFIRMWARE_UPDATE=ON \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo -DTRACE_LEVEL=WARN \
	-DMBED_CLOUD_DEV_UPDATE_ID=ON -DNETWORK_PROXY_SUPPORT=ON \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON

%make_build

%install
install -vdm 0755				                    %{buildroot}/var/lib/pelion/mbed/

install -vdm 0755               %{buildroot}/%{_bindir}
install -vpm 0755 bin/edge-core %{buildroot}/%{_bindir}
install -vpm 0755 %{_filesdir}/launch-edge-core.sh  %{buildroot}/%{_bindir}

install -vdm 0755				                    %{buildroot}/%{_unitdir}
install -vpm 0755 %{_filesdir}/edge-core.service    %{buildroot}/%{_unitdir}

install -vdm 0755 %{buildroot}/%{_sysconfdir}/logrotate.d
install -vpm 0755 %{_filesdir}/edge-core.logrotate	%{buildroot}/%{_sysconfdir}/logrotate.d/edge-core

%files
%{_bindir}/edge-core
%{_bindir}/launch-edge-core.sh
%{_unitdir}/edge-core.service
%{_sysconfdir}/logrotate.d/edge-core

%dir
/var/lib/pelion/mbed/

%post
%systemd_post edge-core.service

%preun
%systemd_preun edge-core.service

%postun
%systemd_postun_with_restart edge-core.service

%changelog
* Fri Jul 30 2021 Nic Costa <nic.costa@pelion.com> - 0.18.0-1
- Initial release of BYOC mode.
