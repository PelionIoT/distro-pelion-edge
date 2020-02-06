#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="mbed-devicejs-bridge"
PELION_PACKAGE_VERSION="0.0.1" # The same value is in debian/control file
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

PELION_PACKAGE_ORIGIN_SOURCE_UPDATE_CALLBACK=pelion_mbed_devicejs_bridge_origin_source_update_cb

PELION_COMPONENT_1_NAME="bridge"
PELION_COMPONENT_1_URL="https://github.com/armPelionEdge/mbed-devicejs-bridge.git"
PELION_COMPONENT_1_VERSION="master"

PELION_COMPONENT_2_NAME="edgejs"
PELION_COMPONENT_2_URL="https://github.com/armPelionEdge/mbed-edge-websocket.git"
PELION_COMPONENT_2_VERSION="master"

PACKAGE_ROOT_DIR=$(cd "$PELION_PACKAGE_DIR/../.."; pwd)
PACKAGE_SOURCE_DIR=$PACKAGE_ROOT_DIR/build/downloads/$PELION_PACKAGE_NAME

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

function pelion_mbed_devicejs_bridge_source_preparation() {
    pelion_source_preparation $PELION_COMPONENT_1_NAME $PELION_COMPONENT_1_URL $PELION_COMPONENT_1_VERSION
    pelion_source_preparation $PELION_COMPONENT_2_NAME $PELION_COMPONENT_2_URL $PELION_COMPONENT_2_VERSION
}

function pelion_mbed_devicejs_bridge_check_no_elf() {
    if find "$1" -type f -exec file {} + | grep -q ELF; then
        echo "Error: $1 have ELF file."
        exit 1
    fi
}

function pelion_mbed_devicejs_bridge_origin_source_update_cb() {
    cd "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/$PELION_COMPONENT_1_NAME" && cp devicejs.json package.json
    npm install
    rm -rf node_modules/mbed-cloud-sdk/.venv

    pelion_mbed_devicejs_bridge_check_no_elf "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/$PELION_COMPONENT_1_NAME/node_modules"

    cd "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/$PELION_COMPONENT_2_NAME"
    npm install

    pelion_mbed_devicejs_bridge_check_no_elf "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/$PELION_COMPONENT_2_NAME/node_modules"
    cp "$PELION_PACKAGE_DIR/config-dev.json" "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/$PELION_COMPONENT_1_NAME/config.json"
}

function main() {
    pelion_parse_args "$@"

    pelion_env_validate

    pelion_mbed_devicejs_bridge_source_preparation
    echo "INFO: Source preparation done!"

    pelion_generation_deb_source_packages
    echo "INFO: Generation debian source packages done!"

    pelion_building_deb_package
    echo "INFO: Building debian package done!"

    echo "INFO: Done!"
}

# Entry point
main "$@"
