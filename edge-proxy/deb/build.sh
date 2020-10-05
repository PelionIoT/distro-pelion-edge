#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="edge-proxy"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["git@github.com:armPelionEdge/edge-proxy.git"]="b0f66f21e84078ff52e11f59f1cc9890a0dfaa34")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
