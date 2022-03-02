%global goipath github.com/armPelionEdge/maestro-shell
%global tag     v2.7.1
%global version v2.7.1
%gometa

Name:           maestro-shell
Version:        2.7.1
Release:        1%{?dist}
Summary:        Shell access to maestro

License:        Apache-2.0
URL:            %{gourl}
Source0:        %{gosource}
Patch0:         greaselib-autoreconf.patch
Patch1:         gperftools-enable-unwind.patch

Requires:       maestro
BuildRequires:  m4 python27 gcc-c++ golang >= 1.16 libunwind-devel

%global __requires_exclude (libgrease\\.so\\.1|libtcmalloc_minimal\\.so\\.4)

%description
An interactive shell for controlling maestro locally on deviceOS.

%prep
%goprep -k
%patch0 -p1
%patch1 -p1

%build
./build-deps.sh
%gobuild -o %{gobuilddir}/bin/%{name} %{goipath}

%install
install -vdm 0755                            %{buildroot}/usr/lib/pelion/bin
install -vpm 0755 %{gobuilddir}/bin/*        %{buildroot}/usr/lib/pelion/bin/
install -vdm 0755                            %{buildroot}/%{_bindir}
install -vpm 0755 %{_filesdir}/maestro-shell %{buildroot}/%{_bindir}/

%files
%{_bindir}/*
/usr/lib/pelion/bin/*

%changelog
* Wed Jun 9 2021 Michael Ray <michael.ray@pelion.com> - 2.7.1-1
- Locked down version of all packages
* Wed May 20 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 0.0.1-1
- Initial release.
