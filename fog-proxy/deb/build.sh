#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="fog-proxy"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["git@github.com:armPelionEdge/fog-proxy.git"]="9eb83a24b44386ff963c99470c38eb7c56f95e9a")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
