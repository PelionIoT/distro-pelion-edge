%global goipath github.com/PelionIoT/edge-kubelet
%global tag     v1.0.0
%global version v1.0.0
%gometa

Name:           kubelet
Version:        1.0.0
Release:        1%{?dist}
Summary:        Talks to kubernetes service

License:        Apache-2.0
URL:            %{gourl}
Source0:        %{gosource}

BuildRequires:  golang-bin >= 1.15
Requires:		conntrack-tools docker-ce containernetworking-plugins containernetworking-plugin-c2d ebtables ethtool iproute iptables util-linux socat
Requires:       edge-proxy pe-utils
Requires(post): systemd-units
Requires(preun): systemd-units
Requires(postun): systemd-units

%description
Talks to Kubernetes service

%prep
%goprep -k
cd ..
mkdir -p ../../k8s.io/
ln -s -f $PWD/edge-kubelet ../../k8s.io/kubernetes

%build
%gobuild k8s.io/kubernetes/cmd/kubelet

%install
install -vdm 0755                                   %{buildroot}/%{_bindir}
install -vpm 0755 %{gobuilddir}/../kubelet          %{buildroot}/%{_bindir}
install -vpm 0755 %{_filesdir}/launch-edgenet.sh    %{buildroot}/%{_bindir}
install -vpm 0755 %{_filesdir}/launch-kubelet.sh    %{buildroot}/%{_bindir}

install -vdm 0755                           %{buildroot}/%{_sysconfdir}/pelion
install -vpm 0644 %{_filesdir}/kubeconfig   %{buildroot}/%{_sysconfdir}/pelion

install -vdm 0755                           %{buildroot}/%{_sysconfdir}/docker
install -vpm 0644 %{_filesdir}/daemon.json  %{buildroot}/%{_sysconfdir}/docker
install -vdm 0755                               %{buildroot}/%{_unitdir}
install -vpm 0644 %{_filesdir}/kubelet.service  %{buildroot}/%{_unitdir}

install -vdm 0755                               %{buildroot}/var/lib/pelion/kubelet/store

install -vdm 0755                                   %{buildroot}/%{_sysconfdir}/cni/net.d/
install -vpm 0644 %{_filesdir}/99-loopback.conf     %{buildroot}/%{_sysconfdir}/cni/net.d/

%files
%{_bindir}/*
%config %{_sysconfdir}/pelion/kubeconfig
%config %{_sysconfdir}/docker/daemon.json
%{_unitdir}/kubelet.service
%{_sysconfdir}/cni/net.d/99-loopback.conf

%dir
/var/lib/pelion/kubelet/store

%post
%systemd_post kubelet.service

%preun
%systemd_preun kubelet.service

%postun
%systemd_postun_with_restart kubelet.service

%changelog
* Wed Jun 9 2021 Michael Ray <michael.ray@pelion.com> - 1.0.0-1
- Locked down version of all packages
* Tue Dec 15 2020 Krzysztof Bembnista <krzysztof.bembnista@globallogic.com> - 0.0.1-1
- Initial release.
