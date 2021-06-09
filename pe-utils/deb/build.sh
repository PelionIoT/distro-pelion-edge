#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="pe-utils"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/armPelionEdge/pe-utils.git"]="cccc67643c2cf0846731573ca0c69faf68a5eb6d")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
