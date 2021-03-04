#!/bin/bash


override_conjure_sources() {
    cd "$cachedir/$tarname"
    git submodule update --init --recursive
    cp "$specdir/../../mbed_cloud_dev_credentials.c" "./config/mbed_cloud_dev_credentials.c"
    cp "$specdir/../../update_default_resources.c" "./config/update_default_resources.c"
    cp "$specdir/files/sotp_fs_linux.h" "./config/sotp_fs_linux.h"
    cp "$specdir/files/osreboot.c" "./edge-core/osreboot.c"
    conjure_sources
}

. "${0%/*}"/../../build-env/inc/rpm-common.sh
