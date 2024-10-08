#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="edge-proxy"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/PelionIoT/edge-proxy.git"]="v1.3.0")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
