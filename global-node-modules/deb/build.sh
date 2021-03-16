#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="global-node-modules"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

PELION_PACKAGE_SKIP_DEPS_CHECKING=true
PELION_PACKAGE_SUPPORTED_ARCH=(amd64 arm64 armhf)
PELION_PACKAGE_ORIGIN_SOURCE_UPDATE_CALLBACK=pelion_global_node_modules_source_update_cb

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/armPelionEdge/edge-node-modules.git"]="1ea6080fcc17e588c4f53c86a6c2b2bd7df3f05c"
    ["https://github.com/armPelionEdge/devjs-production-tools.git"]="master")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

function pelion_global_node_modules_source_update_cb() {
    sudo apt update && sudo apt install -y pe-nodejs
    cd "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/edge-node-modules"
    npm --loglevel silly install --production --ignore-scripts >> npm-second.log 2>&1
    pelion_update_too_old_files "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/edge-node-modules/node_modules"
    mv "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/edge-node-modules"/* "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"
    cd "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME" && \
    rm -rf edge-node-modules
}

pelion_main "$@"
