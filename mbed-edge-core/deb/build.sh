#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="mbed-edge-core"
PELION_PACKAGE_VERSION="0.0.1" # The same value is in debian/control file
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

PELION_PACKAGE_ORIGIN_SOURCE_UPDATE_CALLBACK=pelion_mbed_edge_core_origin_source_update_cb

PELION_COMPONENT_NAME="mbed-edge-core"
PELION_COMPONENT_URL="https://github.com/ARMmbed/mbed-edge.git"
PELION_COMPONENT_VERSION="0.10.0"

# Default value of build options
PELION_PACKAGE_CERTIFICATE_PATH=$PELION_PACKAGE_DIR

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

function pelion_mbed_edge_core_source_preparation() {
    pelion_source_preparation $PELION_COMPONENT_NAME $PELION_COMPONENT_URL $PELION_COMPONENT_VERSION

    cd "$PELION_SOURCE_DIR/$PELION_COMPONENT_NAME"
    git submodule update --init --recursive
}

function pelion_mbed_edge_core_origin_source_update_cb() {
    cp "$PELION_PACKAGE_CERTIFICATE_PATH/mbed_cloud_dev_credentials.c" "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/config/"
}

function main() {
    pelion_parse_args "$@"

    pelion_env_validate

    pelion_mbed_edge_core_source_preparation
    echo "INFO: Source preparation done!"

    pelion_generation_deb_source_packages
    echo "INFO: Generation debian source packages done!"

    pelion_building_deb_package
    echo "INFO: Building debian package done!"

    echo "INFO: Done!"
}

# Entry point
main "$@"
