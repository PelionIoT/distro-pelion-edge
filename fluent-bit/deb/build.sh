#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="fluent-bit"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

PELION_PACKAGE_SOURCE_PREPARATION_CALLBACK=pelion_fluent_bit_source_preparation_cb

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/fluent/fluent-bit.git"]="v1.8.2")
source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

function pelion_fluent_bit_source_preparation_cb() {
    cd "$PELION_SOURCE_DIR/$PELION_PACKAGE_NAME/$PELION_PACKAGE_NAME"
    # fluent-bit source has a debian folder already checked into the repository
    # Remove the fluent-bit debian folder so we can use ours
    # (distro-pelion-edge debian folder gets copied over after this callback)
    rm -rf debian
}

pelion_main "$@"
