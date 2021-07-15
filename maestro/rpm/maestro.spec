%global goipath github.com/armPelionEdge/maestro
%global tag     v2.9.0
%global version v2.9.0
%gometa

Name:          maestro
Version:       2.9.0
Release:       1%{?dist}
Summary:       Pelion Edge systems management daemon

License:       Apache-2.0
URL:           %{gourl}
Source0:       %{gosource}
Patch0:        01_gyp_force_python2.patch
Patch1:        greaselib-autoreconf.patch
Patch2:        gperftools-enable-unwind.patch
Patch3:        eventfd.patch

BuildRequires: m4 python27 gcc-c++ golang < 1.16 libunwind-devel
Requires(post): systemd-units
Requires(preun): systemd-units
Requires(postun): systemd-units

%global __requires_exclude (libgrease\\.so\\.1|libtcmalloc_minimal\\.so\\.4)

%description
Maestro is a replacement for a number of typical system utilities and
management programs, while providing cloud-connected systems management.
Maestro is designed specifically for cloud-connected embedded Linux computers,
with somewhat limited RAM and disk space, where file systems are often flash -
and would prefer less writing over time.

%prep
%goprep -k
%patch0 -p1
%patch1 -p1
%patch2 -p1
%patch3 -p1

%build
topdir=$(pwd)
greasegodir=$topdir/vendor/github.com/armPelionEdge/greasego
greaselibdir=$greasegodir/deps/src/greaseLib

mkdir -p "$greasegodir"/deps/bin
mkdir -p "$greasegodir"/deps/lib

cd "$greaselibdir"/deps
./install-deps.sh

cd "$greaselibdir"
%make_build libgrease.a-server
%make_build libgrease.so.1
%make_build grease_echo
%make_build standalone_test_logsink

cp -r deps/build/lib/* "$greasegodir"/deps/lib
cp -r deps/build/include/* "$greasegodir"/deps/include
cp deps/libuv-v1.10.1/include/uv* "$greasegodir"/deps/include
cp libgrease.so.1 "$greasegodir"/deps/lib
cp *.h "$greasegodir"/deps/include

cd "$greasegodir"/deps/lib
ln -sf libgrease.so.1 libgrease.so

cd "$greasegodir"
DEBUG=1 ./build.sh preprocess_only
rm -rf src
%make_build bindings.a

BUILDTAGS=debug
LDFLAGS="-r %{_libdir}/pelion $LDFLAGS"
%gobuild -o %{gobuilddir}/bin/%{name} %{goipath}/maestro

%install
greaselibdir=vendor/github.com/armPelionEdge/greasego/deps/lib

install -vdm 0755                     %{buildroot}/var/log/pelion
install -vdm 0755                     %{buildroot}/var/lib/pelion/maestro
install -vdm 0755                     %{buildroot}/%{_bindir}
install -vpm 0755 %{gobuilddir}/bin/* %{buildroot}/%{_bindir}/

install -vdm 0755                                         %{buildroot}/usr/lib/pelion
install -vpm 0644 "$greaselibdir"/libgrease.so*           %{buildroot}/usr/lib/pelion/
install -vpm 0644 "$greaselibdir"/libtcmalloc_minimal.so* %{buildroot}/usr/lib/pelion/

install -vdm 0755                               %{buildroot}/%{_sysconfdir}/pelion/template
install -vpm 0644 %{_filesdir}/relay-term-config.json  %{buildroot}/%{_sysconfdir}/pelion
install -vpm 0644 %{_filesdir}/pelion-base-config.yaml  %{buildroot}/%{_sysconfdir}/pelion

install -vdm 0755                               %{buildroot}/%{_unitdir}
install -vpm 0644 %{_filesdir}/maestro.service  %{buildroot}/%{_unitdir}

%files
%{_bindir}/*
/usr/lib/pelion
%{_unitdir}/maestro.service
%{_sysconfdir}/pelion/template/*
%config %{_sysconfdir}/pelion/pelion-base-config.yaml

%dir
/var/lib/pelion/maestro
/var/log/pelion

%post
%systemd_post maestro.service

%preun
%systemd_preun maestro.service

%postun
%systemd_postun_with_restart maestro.service

%changelog
* Wed Jun 9 2021 Michael Ray <michael.ray@pelion.com> - 2.9.0-1
- Locked down version of all packages
* Wed May 20 2020 Vasily Smirnov <vasilii.smirnov@globallogic.com> - 0.0.1-1
- Initial release.
