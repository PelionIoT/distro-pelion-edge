#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="pe-golang-bin"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)
PELION_PACKAGE_TARBALL=go1.14.13.linux-amd64.tar.gz

source "$PELION_PACKAGE_DIR"/../../../build-env/inc/build-common.sh

function golang_download {
    local PACKAGE_COMPONENT_SOURCE_DIR=${PELION_SOURCE_DIR}/${PELION_PACKAGE_NAME}/

    echo "Downloading Go"
    mkdir -p $PACKAGE_COMPONENT_SOURCE_DIR
    wget -c https://golang.org/dl/$PELION_PACKAGE_TARBALL -P $PACKAGE_COMPONENT_SOURCE_DIR
}

function golang_unpack {
    local PACKAGE_COMPONENT_SOURCE_DIR=${PELION_SOURCE_DIR}/${PELION_PACKAGE_NAME}/
    local PACKAGE_TMP_FOLDER="$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"
    echo "Unpacking Go"
    rm -rf "$PELION_TMP_BUILD_DIR"
    mkdir -p "${PACKAGE_TMP_FOLDER}"
    tar xf ${PACKAGE_COMPONENT_SOURCE_DIR}/${PELION_PACKAGE_TARBALL} -C "${PACKAGE_TMP_FOLDER}"
}

PELION_PACKAGE_SOURCE_PREPARATION_CALLBACK=golang_download
PELION_PACKAGE_ORIGIN_SOURCE_UPDATE_CALLBACK=golang_unpack

pelion_main "$@"
