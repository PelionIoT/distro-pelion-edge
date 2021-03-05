#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="edge-proxy"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/armPelionEdge/edge-proxy.git"]="7e70a2f1cc32e7cd732d5abfa41857da017abb24")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
