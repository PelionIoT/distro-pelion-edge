#!/bin/bash

override_conjure_sources() {
    cd "$cachedir/$tarname"
    npm install
    conjure_sources
}

. "${0%/*}"/../../build-env/inc/rpm-common.sh
