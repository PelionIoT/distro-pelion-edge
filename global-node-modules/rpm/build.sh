#!/bin/bash

read -rd '' overrides_json <<'EOF'
{
    "devjs-configurator": "http://github.com/armPelionEdge/devjs-configurator#master"
}
EOF

override_download() {
    download "https://github.com/armPelionEdge/devjs-production-tools" \
             "9f795d20bc68b0a49f4e1b004429aed6ba073a4b"
    download "https://github.com/armPelionEdge/edge-node-modules" \
             "122835410976f23b6694d925d993e72c50ced053"
}

override_conjure_sources() {
    cd "$cachedir/devjs-production-tools"
    npm install

    cd "$cachedir/edge-node-modules"
    printf '%s' "$overrides_json" >"overrides.json"

    rm -f package.json
    node "$cachedir"/devjs-production-tools/consolidator.js -O overrides.json -d grease-log -d dhclient -d WWSupportTunnel ./*/
    sed -i '/isc-dhclient/d' ./package.json
    sed -i '/node-hotplug/d' ./package.json

    npm install --loglevel silly node-expat iconv bufferutil@3.0.5 --production --ignore-scripts
    npm --loglevel silly install --production --ignore-scripts

    tar --xform "s/^\./edge-node-modules/" \
         -cf "$builddir/edge-node-modules.tar.gz" .
}

. "${0%/*}"/../../build-env/inc/rpm-common.sh
