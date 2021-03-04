#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="edge-proxy"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/armPelionEdge/edge-proxy.git"]="8073dda0f9fc0c0906493089792faa48dc27a569")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
