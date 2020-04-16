%global goipath github.com/armPelionEdge/maestro-shell
%global commit  6453fba93557fc7c4593c48022cf88395bd23a57
%gometa

Name:           maestro-shell
Version:        0.0.1
Release:        1%{?dist}
Summary:        Shell access to maestro

License:        Apache-2.0
URL:            %{gourl}
Source0:        %{gosource}

%description
An interactive shell for controlling maestro locally on deviceOS.

%prep
%goprep -k

%build
%gobuild -o %{gobuilddir}/bin/%{name} %{goipath}

%install
install -vdm 0755                     %{buildroot}/%{_bindir}
install -vpm 0755 %{gobuilddir}/bin/* %{buildroot}/%{_bindir}/

%files
%{_bindir}/*

%changelog
* Wed May 20 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 0.0.1-1
- Initial release.
