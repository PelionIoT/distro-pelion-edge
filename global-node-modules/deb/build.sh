#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="global-node-modules"
PELION_PACKAGE_VERSION="0.0.1" # The same value is in debian/control file
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

PELION_PACKAGE_SKIP_DEPS_CHECKING=true
PELION_PACKAGE_SUPPORTED_ARCH=(amd64 arm64 armhf)
PELION_PACKAGE_ORIGIN_SOURCE_UPDATE_CALLBACK=pelion_global_node_modules_source_update_cb

PELION_COMPONENT_1_NAME="edge-node-modules"
PELION_COMPONENT_1_URL="https://github.com/armPelionEdge/edge-node-modules.git"
PELION_COMPONENT_1_VERSION="master"

PELION_COMPONENT_2_NAME="devjs-production-tools"
PELION_COMPONENT_2_URL="https://github.com/armPelionEdge/devjs-production-tools.git"
PELION_COMPONENT_2_VERSION="master"

PACKAGE_ROOT_DIR=$(cd "$PELION_PACKAGE_DIR/../.."; pwd)
PACKAGE_SOURCE_DIR=$PACKAGE_ROOT_DIR/build/downloads/$PELION_PACKAGE_NAME

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

function pelion_global_node_modules_source_preparation() {
    pelion_source_preparation $PELION_COMPONENT_1_NAME $PELION_COMPONENT_1_URL $PELION_COMPONENT_1_VERSION
    pelion_source_preparation $PELION_COMPONENT_2_NAME $PELION_COMPONENT_2_URL $PELION_COMPONENT_2_VERSION
}

function pelion_global_node_modules_source_update_cb() {
    echo -en "{\n\"devjs-configurator\": \"http://github.com/armPelionEdge/devjs-configurator#master\"\n}\n" > "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/$PELION_COMPONENT_1_NAME/overrides.json"

    cd "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/$PELION_COMPONENT_2_NAME"
    npm install --ignore-scripts

    cd "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/$PELION_COMPONENT_1_NAME"

    node ../$PELION_COMPONENT_2_NAME/consolidator.js -O overrides.json -d grease-log -d dhclient -d WWSupportTunnel ./*
    sed -i '/isc-dhclient/d' ./package.json
    sed -i '/node-hotplug/d' ./package.json

    npm install --loglevel silly node-expat iconv bufferutil@3.0.5 --production --ignore-scripts >> npm-first.log 2>&1
    rm package-lock.json
    npm install --loglevel silly install --production --ignore-scripts >> npm-second.log 2>&1
    rm package-lock.json
}

function main() {
    pelion_parse_args "$@"

    pelion_env_validate

    pelion_global_node_modules_source_preparation
    echo "INFO: Source preparation done!"

    pelion_generation_deb_source_packages
    echo "INFO: Generation debian source packages done!"

    pelion_building_deb_package
    echo "INFO: Building debian package done!"

    echo "INFO: Done!"
}

# Entry point
main "$@"
