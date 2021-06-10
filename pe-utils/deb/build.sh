#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="pe-utils"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/armPelionEdge/pe-utils.git"]="f90c6a01714db17b1c97a4912db044c6878a4b59")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
