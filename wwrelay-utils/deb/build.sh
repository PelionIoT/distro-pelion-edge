#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="wwrelay-utils"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["git@github.com:armPelionEdge/edge-utils.git"]="0eaf84d562d8bde2dd5e13c0a1c2fbc249eb78d3")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
