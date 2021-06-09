%global forgeurl https://github.com/ARMmbed/mbed-edge-examples
%global tag     0.10.0
%global version 0.10.0
%forgemeta
%global builddir %{_builddir}/%{archivename}
%global debug_package %{nil}

Name:           mbed-edge-examples
Version:        0.10.0
Release:        1%{?dist}
Summary:        examples for mbed-edge protocol translatior

License:        Apache-2.0
URL:            %{forgeurl}
Source0:        %{forgesource}

BuildRequires:  cmake glib2-devel mosquitto-devel python2 doxygen

%description
The  protocol translator  acts as  a bridge  between Edge  Core and  the device.
Devices connect to  Edge through protocols not known in  advance, and therefore,
you need to  handle the connecting and disconnecting. Neither  the Edge Core API
nor the protocol  translator API currently track the connected  devices or their
lifetimes. Therefore,  they do not  automatically clean up  disconnected devices
from their internal lists. The role of  the protocol translator is to bridge any
arbitrary data format to an LwM2M-compatible format. The protocol translator API
provides an interface to interact with  Edge Core and expose Resources to Device
Management. You  need to translate  the incoming  data from devices  to Objects,
Object Instances, and Resources using this API.

%prep
%setup -q %{forgesetupargs}

%build
make build-all-examples

%install
install -vdm 0755 %{buildroot}/%{_bindir}

for x in pt blept mqttpt; do
  install -vpm 0755 %{builddir}/build/bin/$x-example %{buildroot}/%{_bindir}
done

for x in ep gw; do
  install -vpm 0755 %{builddir}/mqttpt-example/mqttgw_sim/mqtt_$x.sh %{buildroot}/%{_bindir}
done

%files
%{_bindir}/*

%changelog
* Wed Jun 9 2021 Michael Ray <michael.ray@pelion.com> - 0.10.0-1
- Locked down version of all packages
* Wed May 20 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 0.0.1-1
- Initial release.
