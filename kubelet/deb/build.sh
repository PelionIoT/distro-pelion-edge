#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="kubelet"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/armPelionEdge/edge-kubelet.git"]="83b266ae6939012883611d6dbda745f2490a67c4")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
