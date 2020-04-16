#!/bin/bash

override_download() {
    download "https://github.com/armPelionEdge/mbed-devicejs-bridge" \
             "b9cb430e57cf4660d585c23db0e82756a567c652"
    download "https://github.com/armPelionEdge/mbed-edge-websocket" \
             "79ee162ba5f6eb2b226500e1f8bd3d7f07ee7f45"
}

override_conjure_sources() {
    cd "$cachedir/mbed-devicejs-bridge"
    npm install
    rm -rf node_modules/mbed-cloud-sdk/.venv
    cp "$specdir/config-dev.json" config.json

    cd "$cachedir/mbed-edge-websocket"
    npm install

    cd "$cachedir"
    tar -czf "$builddir/mbed-devicejs-bridge.tar.gz" \
        --xform "s/^\./mbed-devicejs-bridge/"        \
        ./mbed-devicejs-bridge                       \
        ./mbed-edge-websocket
}

. "${0%/*}"/../../build-env/inc/rpm-common.sh
