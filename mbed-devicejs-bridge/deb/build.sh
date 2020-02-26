#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="mbed-devicejs-bridge"
PELION_PACKAGE_VERSION="0.0.1" # The same value is in debian/control file
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

PELION_PACKAGE_ORIGIN_SOURCE_UPDATE_CALLBACK=pelion_mbed_devicejs_bridge_origin_source_update_cb

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/armPelionEdge/mbed-devicejs-bridge.git"]="master"
    ["https://github.com/armPelionEdge/mbed-edge-websocket.git"]="master")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

function pelion_mbed_devicejs_bridge_check_no_elf() {
    if find "$1" -type f -exec file {} + | grep -q ELF; then
        echo "Error: $1 have ELF file."
        exit 1
    fi
}

function pelion_mbed_devicejs_bridge_origin_source_update_cb() {
    cd "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/mbed-devicejs-bridge" && cp devicejs.json package.json
    npm install
    rm -rf node_modules/mbed-cloud-sdk/.venv

    pelion_mbed_devicejs_bridge_check_no_elf "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/mbed-devicejs-bridge/node_modules"
    cp "$PELION_PACKAGE_DIR/config-dev.json" "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/mbed-devicejs-bridge/config.json"

    cd "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/mbed-edge-websocket"
    npm install

    pelion_mbed_devicejs_bridge_check_no_elf "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/mbed-edge-websocket/node_modules"
}

pelion_main "$@"
