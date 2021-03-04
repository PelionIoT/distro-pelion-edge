#!/bin/bash

override_conjure_sources() {
    cd "$cachedir/$tarname"
    git submodule update --init --recursive
    conjure_sources
}

override_post_install_deps() {
    sudo alternatives --set python /usr/bin/python2
}

. "${0%/*}"/../../build-env/inc/rpm-common.sh
