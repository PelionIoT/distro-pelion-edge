#!/bin/bash

override_conjure_sources() {
    cd "$cachedir/$tarname"
    git submodule update --init --recursive
    cp "$specdir/files/mbed_cloud_client_user_config.h" "./config/mbed_cloud_client_user_config.h"
    cp "$specdir/files/sotp_fs_linux.h" "./config/sotp_fs_linux.h"
    cp "$specdir/files/osreboot.c" "./edge-core/osreboot.c"
    # update the mbed-cloud-client library
    sed -i 's!/dev/random!/dev/urandom!' lib/mbed-cloud-client/mbed-client-pal/Source/Port/Reference-Impl/OS_Specific/Linux/Board_Specific/TARGET_x86_x64/pal_plat_x86_x64.c || true
    sed -i 's!\(MAX_RECONNECT_TIMEOUT\).*!\1 60!' lib/mbed-cloud-client/mbed-client/mbed-client/m2mconstants.h || true
    conjure_sources
}

. "${0%/*}"/../../build-env/inc/rpm-common.sh
