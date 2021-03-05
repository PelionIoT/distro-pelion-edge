#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="devicedb"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/armPelionEdge/devicedb.git"]="d24df289ab24a035ebf64d2ed27a2d531a2319da")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
