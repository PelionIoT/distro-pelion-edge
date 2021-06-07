#!/bin/bash

override_download() {
    download "https://github.com/armPelionEdge/devjs-production-tools" \
             "master"
    download "https://github.com/armPelionEdge/edge-node-modules" \
             "1ea6080fcc17e588c4f53c86a6c2b2bd7df3f05c"
}

override_conjure_sources() {
    cd "$cachedir/edge-node-modules"
    npm --loglevel silly install --production --ignore-scripts

    tar --xform "s/^\./edge-node-modules/" \
         -cf "$builddir/edge-node-modules.tar.gz" .
}

. "${0%/*}"/../../build-env/inc/rpm-common.sh
