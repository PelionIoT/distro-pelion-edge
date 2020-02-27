#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="mbed-edge-core"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

PELION_PACKAGE_SOURCE_PREPARATION_CALLBACK=pelion_mbed_edge_core_source_preparation
PELION_PACKAGE_ORIGIN_SOURCE_UPDATE_CALLBACK=pelion_mbed_edge_core_origin_source_update_cb

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/ARMmbed/mbed-edge.git"]="0.10.0")

PELION_PACKAGE_CERTIFICATE_PATH=$PELION_PACKAGE_DIR

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

function pelion_mbed_edge_core_source_preparation() {
    cd "$PELION_SOURCE_DIR/mbed-edge"
    git submodule update --init --recursive
}

function pelion_mbed_edge_core_origin_source_update_cb() {
    cp "$PELION_PACKAGE_CERTIFICATE_PATH/mbed_cloud_dev_credentials.c" "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/config/"
}

pelion_main "$@"
