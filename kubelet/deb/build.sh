#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="kubelet"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/armPelionEdge/edge-kubelet.git"]="v1.1.0")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
