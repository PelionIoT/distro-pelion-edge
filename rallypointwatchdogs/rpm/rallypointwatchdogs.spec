%global goipath github.com/armPelionEdge/rallypointwatchdogs
%global commit  54ee3bd50b063425606ad76aefad4167780d8760
%gometa

Name:           rallypointwatchdogs
Version:        0.0.1
Release:        1%{?dist}
Summary:        rallyPoint Maestro Watchdog

License:        Apache-2.0
URL:            %{gourl}
Source0:        %{gosource}

%description
RallyPoint 100 & 200 watchdog plugins for maestro

%prep
%goprep -k

%build
%{?gobuilddir:export GOPATH="%{gobuilddir}:${GOPATH:+${GOPATH}:}%{?gopath}"}

# For some reason the Go compiler doesn't work well with vendor
# directories in the plugin build mode, so we have to copy those under
# GOPATH.
cp -r vendor/. %{gobuilddir}/src/

cd rp100
go build -buildmode=plugin -o rp100wd.so wd.go
cd ../dummy
go build -buildmode=plugin -o dummywd.so wd.go

%install
install -vdm 0755   %{buildroot}/%{_libdir}/pelion
cp rp100/rp100wd.so %{buildroot}/%{_libdir}/pelion
cp dummy/dummywd.so %{buildroot}/%{_libdir}/pelion

%files
%{_libdir}/pelion/rp100wd.so
%{_libdir}/pelion/dummywd.so

%changelog
* Wed May 27 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 0.0.1-1
- Initial release.
