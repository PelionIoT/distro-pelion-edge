#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="pe-utils"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/armPelionEdge/pe-utils.git"]="f7d3e32373eb5ed8536f70110406ad35c2e5e0cb")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
