#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="edge-proxy"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["git@github.com:armPelionEdge/edge-proxy.git"]="883e6cb16db4a5b97302c54ba36ee5566ea8557b")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
