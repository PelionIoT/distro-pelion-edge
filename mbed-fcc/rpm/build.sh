#!/bin/bash

override_download() {
    download "https://github.com/PelionIoT/factory-configurator-client-example" \
             "4.6.0"
    download "https://github.com/PelionIoT/mbed-cloud-client" \
             "4.6.0"
}

override_conjure_sources() {
    cp -a "$cachedir/factory-configurator-client-example" "$builddir/mbed-fcc"
    cp -a "$cachedir/mbed-cloud-client"                   "$builddir/mbed-fcc/"
    cd "$builddir/mbed-fcc"

    check_python_dep requests
    check_python_dep click

    PYTHONUSERBASE=. python3 pal-platform/pal-platform.py -v deploy --target=Yocto_Generic_YoctoLinux_mbedtls generate

    cd ..
    tar -caf mbed-fcc.tar.gz mbed-fcc
}

. "${0%/*}"/../../build-env/inc/rpm-common.sh
