#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="mbed-edge-examples"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

PELION_PACKAGE_SOURCE_PREPARATION_CALLBACK=pelion_mbed_edge_examples_source_preparation
PELION_PACKAGE_PRE_BUILD_CALLBACK=configure_python

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/PelionIoT/mbed-edge-examples.git"]="0.21.0")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

function pelion_mbed_edge_examples_source_preparation() {
    cd "$PELION_SOURCE_DIR/$PELION_PACKAGE_NAME/mbed-edge-examples"
    git submodule update --init --recursive
}

pelion_main "$@"
