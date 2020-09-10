#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="pe-utils"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/armPelionEdge/pe-utils.git"]="b398d270aec33cf1be6811dc7d65e9c9d6c0389d")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
