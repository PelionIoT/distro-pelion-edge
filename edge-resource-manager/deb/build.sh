#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="edge-resource-manager"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

PELION_PACKAGE_PRE_BUILD_CALLBACK='select_python 3'

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/PelionIoT/edge-resource-manager.git"]="v1.0.0")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
