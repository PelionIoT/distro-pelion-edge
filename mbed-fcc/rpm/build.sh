#!/bin/bash

override_download() {
    download "https://github.com/ARMmbed/factory-configurator-client-example" \
             "dc3862efd6e7b3cbc6f10f34673c76e6fd968a3a"
    download "https://github.com/ARMmbed/mbed-cloud-client" \
             "e03c516af9c9137b56d9c2620a293c79f1f867f8"
}

override_conjure_sources() {
    cp -a "$cachedir/factory-configurator-client-example" "$builddir/mbed-fcc"
    cp -a "$cachedir/mbed-cloud-client"                   "$builddir/mbed-fcc/"
    cd "$builddir/mbed-fcc"

    check_python_dep requests
    check_python_dep click
    PYTHONUSERBASE=. \
    python3 pal-platform/pal-platform.py -v deploy --target=x86_x64_NativeLinux_mbedtls generate

    cd ..
    tar -caf mbed-fcc.tar.gz mbed-fcc
}

. "${0%/*}"/../../build-env/inc/rpm-common.sh
