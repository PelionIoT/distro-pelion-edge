#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="pe-utils"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

PELION_PACKAGE_SKIP_DEPS_CHECKING=true
PELION_PACKAGE_ORIGIN_SOURCE_UPDATE_CALLBACK=pelion_pe_utils_origin_source_update_cb

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/armPelionEdge/pe-utils.git"]="master")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

function pelion_pe_utils_check_no_elf() {
    if find "$1" -type f -exec file {} + | grep -q ELF; then
        echo "Error: $1 have ELF file."
        exit 1
    fi
}

function pelion_pe_utils_origin_source_update_cb() {
    cd  "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/identity-tools/developer_identity"
    npm install

    pelion_pe_utils_check_no_elf "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/identity-tools/developer_identity/node_modules"
    chmod +x "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/identity-tools/generate-identity.sh"
}

pelion_main "$@"
