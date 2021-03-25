%define name    containernetworking-plugin-c2d
%define version 0.0.1
%define release 1%{?dist}

Name: %{name}
Version: %{version}
Release: %{release}

BuildArch:      noarch
Summary:        CNI c2d plugin

License:        Apache-2.0
Requires:       containernetworking-plugins

%description
Provides additional c2d CNI plugin

%install
install -vdm 0755                           %{buildroot}/usr/libexec/cni
install -vpm 0755 %{_filesdir}/c2d          %{buildroot}/usr/libexec/cni
install -vpm 0755 %{_filesdir}/c2d-inner    %{buildroot}/usr/libexec/cni

install -vdm 0755                           %{buildroot}/%{_sysconfdir}/cni/net.d/
install -vpm 0644 %{_filesdir}/10-c2d.conf       %{buildroot}/%{_sysconfdir}/cni/net.d/

%files
/usr/libexec/cni/c2d
/usr/libexec/cni/c2d-inner
%{_sysconfdir}/cni/net.d/10-c2d.conf

%changelog
* Mon Mar 1 2021 Krzysztof Bembnista <krzysztof.bembnista@globallogic.com> - 0.0.1-1
- Initial release.
