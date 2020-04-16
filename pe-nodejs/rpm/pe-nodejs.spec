Name:           pe-nodejs
Version:        8.11.4
Release:        1%{?dist}
Summary:        Node.js javascript engine for Pelion Edge applications
License:        MIT and ASL 2.0 and ISC and BSD
URL:            http://nodejs.org/

# This package contains a single prebuilt binary of Node.js from
# https://nodejs.org/dist/v%{version} (all files except bin/node
# were removed).
Source0:        pe-node-%{version}

ExclusiveArch:  %{nodejs_arches}

%description
Node.js engine that is compatible with Pelion Edge javascript
applications.

%prep

%build

%install
install -vdm 0755                    %{buildroot}/%{_libdir}/pelion
install -vpm 0755 pe-node-%{version} %{buildroot}/%{_libdir}/pelion/node

%files
%{_libdir}/pelion/node

%changelog
* Wed May 20 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 8.11.4-1
- Initial release.
