#!/bin/bash

override_download() {
    cd "$cachedir"
    mkdir -p "$package"
}

. "${0%/*}"/../../build-env/inc/rpm-common.sh
