%global forgeurl https://github.com/armPelionEdge/edgeos-wd
%global commit   0415f0887e050c1b1d78b2cdd73692f607e5e0af
%forgemeta

Name:           deviceoswd
Version:        0.0.1
Release:        1%{?dist}
Summary:        The Pelion Edge watchdog
License:        Apache-2.0
URL:            %{forgeurl}
Source0:        %{forgesource}

BuildRequires:  gcc
BuildRequires:  gcc-c++
BuildRequires:  make
BuildRequires:  libtool
BuildRequires:  glibc-static
BuildRequires:  libstdc++-static

%description
Watchdog daemon for edge

%prep
%forgesetup

%build
./deps/install-deps.sh

make clean
make deviceOSWD-dummy
cp deviceOSWD deviceOSWD_dummy

make clean
make deviceOSWD-dummy-debug
cp deviceOSWD deviceOSWD_dummy_debug

make clean
make deviceOSWD-a10-debug
cp deviceOSWD deviceOSWD_a10_debug

make clean
make deviceOSWD-a10

make clean
make deviceOSWD-a10-relay
cp deviceOSWD deviceOSWD_a10_relay

make clean
make deviceOSWD-a10-tiny841
cp deviceOSWD deviceOSWD_a10_tiny841

make clean
make deviceOSWD-rpi-3bplus
cp deviceOSWD deviceOSWD_rpi_3bplus

%install
install -vdm 0755            %{buildroot}/%{_bindir}
cp -a deviceOSWD             %{buildroot}/%{_bindir}
cp -a deviceOSWD_dummy       %{buildroot}/%{_bindir}
cp -a deviceOSWD_a10_debug   %{buildroot}/%{_bindir}
cp -a deviceOSWD_a10_relay   %{buildroot}/%{_bindir}
cp -a deviceOSWD_dummy_debug %{buildroot}/%{_bindir}
cp -a deviceOSWD_a10_tiny841 %{buildroot}/%{_bindir}

%files
%{_bindir}/*

%changelog
* Wed May 27 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 0.0.1-1
- Initial release.
