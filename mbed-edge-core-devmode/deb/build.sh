#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="mbed-edge-core-devmode"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

PELION_PACKAGE_SOURCE_PREPARATION_CALLBACK=pelion_mbed_edge_core_source_preparation_cb

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/ARMmbed/mbed-edge.git"]="0.10.0")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

function pelion_mbed_edge_core_source_preparation_cb() {
    cd "$PELION_SOURCE_DIR/mbed-edge"
    git submodule update --init --recursive
}

pelion_main "$@"
