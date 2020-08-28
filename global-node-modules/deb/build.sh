#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="global-node-modules"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

PELION_PACKAGE_SKIP_DEPS_CHECKING=true
PELION_PACKAGE_SUPPORTED_ARCH=(amd64 arm64 armhf)
PELION_PACKAGE_ORIGIN_SOURCE_UPDATE_CALLBACK=pelion_global_node_modules_source_update_cb

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/armPelionEdge/edge-node-modules.git"]="a70efd3dd4c35904937c2707403313cc3023b025"
    ["https://github.com/armPelionEdge/devjs-production-tools.git"]="master")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

function pelion_global_node_modules_source_update_cb() {
    cd "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/devjs-production-tools"
    npm install

    echo -en "{\n\"devjs-configurator\": \"http://github.com/armPelionEdge/devjs-configurator#master\"\n}\n" > "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/edge-node-modules/overrides.json"

    cd "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/edge-node-modules"

    node ../devjs-production-tools/consolidator.js -O overrides.json -d grease-log -d dhclient -d WWSupportTunnel ./*/
    sed -i '/isc-dhclient/d' ./package.json
    sed -i '/node-hotplug/d' ./package.json

    rm -rf "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/devjs-production-tools"

    npm install --loglevel silly node-expat iconv bufferutil@3.0.5 --production --ignore-scripts >> npm-first.log 2>&1
    npm --loglevel silly install --production --ignore-scripts >> npm-second.log 2>&1

    pelion_update_too_old_files "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/edge-node-modules/node_modules"

    mv "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/edge-node-modules"/* "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"
    cd "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME" && \
    rm -rf edge-node-modules
}

pelion_main "$@"
