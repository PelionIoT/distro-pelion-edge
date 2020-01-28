#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="mbed-edge-examples"
PELION_PACKAGE_VERSION="0.0.1" # The same value is in debian/control file
PELION_PACKAGE_DIR=$(cd `dirname $0` && pwd)

PELION_COMPONENT_NAME="mbed-edge-examples"
PELION_COMPONENT_URL="https://github.com/ARMmbed/mbed-edge-examples.git"
PELION_COMPONENT_VERSION="0.9.0"

PACKAGE_ROOT_DIR=$(cd "$PELION_PACKAGE_DIR/../.."; pwd)
SOURCE_DIR=$PACKAGE_ROOT_DIR/build/downloads

source $PELION_PACKAGE_DIR/../../build-env/inc/build-common.sh

function pelion_mbed_edge_examples_source_preparation() {
    pelion_source_preparation $PELION_COMPONENT_NAME $PELION_COMPONENT_URL $PELION_COMPONENT_VERSION

    cd $SOURCE_DIR/$PELION_COMPONENT_NAME
    git submodule update --init --recursive
}

function main() {
    pelion_parse_args "$@"

    pelion_env_validate

    pelion_mbed_edge_examples_source_preparation
    echo "INFO: Source preparation done!"

    pelion_generation_deb_source_packages
    echo "INFO: Generation debian source packages done!"

    pelion_building_deb_package
    echo "INFO: Building debian package done!"

    echo "INFO: Done!"
}

# Entry point
main $@
