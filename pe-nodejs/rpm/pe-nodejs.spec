Name:           pe-nodejs
Version:        8.11.4
Release:        1%{?dist}
Summary:        Node.js javascript engine for Pelion Edge applications
License:        MIT and ASL 2.0 and ISC and BSD
URL:            http://nodejs.org/

ExclusiveArch:  %{nodejs_arches}

%global __brp_mangle_shebangs_exclude_from /
%global pelibdir    /usr/lib/pelion
%global __requires_exclude node npm

%description
Node.js engine that is compatible with Pelion Edge javascript
applications.

%prep

%build

%install
install -vdm 0755 %{buildroot}/%{pelibdir}
install -vdm 0755 %{buildroot}/%{_bindir}
cp -v -r --preserve=mode %{_builddir}/node_root	-T %{buildroot}/%{pelibdir}

# fix to python2 - python3 incompatible with gyp in this version
grep -ErIzl '^#!(/usr/bin/env python|/usr/bin/python)' %{buildroot} | xargs -l sed -E '1 s|.*|#!/usr/bin/python2|' -i

%files
%{pelibdir}/*

%changelog
* Wed May 20 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 8.11.4-1
- Initial release.
