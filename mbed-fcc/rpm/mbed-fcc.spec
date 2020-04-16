%global debug_package %{nil}

Name:           mbed-fcc
Version:        0.0.1
Release:        1%{?dist}
Summary:        A factory configurator client example

License:        Apache-2.0
URL:            https://github.com/ARMmbed/factory-configurator-client-example

# The source for this package was generated via
# https://github.com/armPelionEdge/ubuntu-pelion-edge-internal
Source0:        mbed-fcc.tar.gz

BuildRequires:  cmake

%description
Factory client tool for preparing for registration.

%prep
%setup -q -n mbed-fcc

%build
%global pal_platform __x86_x64_NativeLinux_mbedtls
cd %{pal_platform}

%cmake -DCMAKE_BUILD_TYPE=Release \
       -DCMAKE_TOOLCHAIN_FILE=../pal-platform/Toolchain/GCC/GCC.cmake \
       -DEXTERNAL_DEFINE_FILE=../linux-config.cmake

%make_build factory-configurator-client-example.elf

%install
install -vdm 0755 %{buildroot}/%{_bindir}
install -vpm 0755 %{pal_platform}/Release/factory-configurator-client-example.elf %{buildroot}/%{_bindir}

%files
%{_bindir}/*

%changelog
* Thu May 21 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 0.0.1-1
- Initial release.
