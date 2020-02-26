#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="devicejs-ng"
PELION_PACKAGE_VERSION="0.0.1" # The same value is in debian/control file
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

PELION_PACKAGE_SKIP_DEPS_CHECKING=true
PELION_PACKAGE_SUPPORTED_ARCH=(amd64 arm64 armhf)
PELION_PACKAGE_ORIGIN_SOURCE_UPDATE_CALLBACK=pelion_devicejs_ng_origin_source_update_cb

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/armPelionEdge/devicejs-ng.git"]="master")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

function pelion_devicejs_ng_origin_source_update_cb() {
    cd  "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"
    npm install --production --ignore-scripts
}

pelion_main "$@"
