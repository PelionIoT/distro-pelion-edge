%global debug_package %{nil}
%global tag     4.9.0
%global version 4.9.0

Name:           mbed-fcc
Version:        4.9.0
Release:        1%{?dist}
Summary:        A factory configurator client example

License:        Apache-2.0
URL:            https://github.com/ARMmbed/factory-configurator-client-example

# The source for this package was generated via
# https://github.com/armPelionEdge/ubuntu-pelion-edge-internal
Source0:        mbed-fcc.tar.gz
Patch0:         0002-Modified-FCCE-to-take-in-CBOR-file-to-generate-the-s.patch

BuildRequires:  cmake python3-click python3-requests python3
Requires(post): systemd-units
Requires(preun): systemd-units
Requires(postun): systemd-units

%description
Factory client tool for preparing for registration.

%prep
%setup -q -n mbed-fcc
%patch0 -p1

%build
%global pal_platform __Yocto_Generic_YoctoLinux_mbedtls
cd %{pal_platform}

%cmake -DCMAKE_BUILD_TYPE=Release \
       -DCMAKE_TOOLCHAIN_FILE=../pal-platform/Toolchain/GCC/GCC.cmake \
       -DEXTERNAL_DEFINE_FILE=../linux-config.cmake

%make_build factory-configurator-client-example.elf

%install
install -vdm 0755 %{buildroot}/%{_bindir}
install -vpm 0755 %{pal_platform}/Release/factory-configurator-client-example.elf %{buildroot}/%{_bindir}
install -vpm 0755 %{_filesdir}/launch-fcc.sh %{buildroot}/%{_bindir}

install -vdm 0755                               %{buildroot}/%{_unitdir}
install -vpm 0644 %{_filesdir}/mbed-fcc.service  %{buildroot}/%{_unitdir}

%files
%{_bindir}/*
%{_unitdir}/mbed-fcc.service

%post
%systemd_post mbed-fcc.service

%preun
%systemd_preun mbed-fcc.service

%postun
%systemd_postun_with_restart mbed-fcc.service

%changelog
* Wed Jun 9 2021 Michael Ray <michael.ray@pelion.com> - 4.9.0-1
- Locked down version of all packages
* Thu May 21 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 0.0.1-1
- Initial release.
