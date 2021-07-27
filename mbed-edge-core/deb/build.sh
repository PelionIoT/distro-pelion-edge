#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="mbed-edge-core"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

PELION_PACKAGE_SOURCE_PREPARATION_CALLBACK=pelion_mbed_edge_core_source_preparation_cb

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/ARMmbed/mbed-edge.git"]="0.18.0")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

function pelion_mbed_edge_core_source_preparation_cb() {
    cd "$PELION_SOURCE_DIR/$PELION_PACKAGE_NAME/mbed-edge"
    git submodule update --init --recursive
    cp "$PELION_PACKAGE_DIR/debian/files/sotp_fs_linux.h" "./config/sotp_fs_linux.h"
    cp "$PELION_PACKAGE_DIR/debian/files/osreboot.c" "./edge-core/osreboot.c"
    cp "$PELION_PACKAGE_DIR/debian/files/mbed_cloud_client_user_config.h" "./config/mbed_cloud_client_user_config.h"

    # update the mbed-cloud-client library
    sed -i 's!/dev/random!/dev/urandom!' lib/mbed-cloud-client/mbed-client-pal/Source/Port/Reference-Impl/OS_Specific/Linux/Board_Specific/TARGET_x86_x64/pal_plat_x86_x64.c || true
    sed -i 's!\(MAX_RECONNECT_TIMEOUT\).*!\1 60!' lib/mbed-cloud-client/mbed-client/mbed-client/m2mconstants.h || true
}

pelion_main "$@"
