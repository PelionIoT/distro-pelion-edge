#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="devicedb"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["git@github.com:armPelionEdge/devicedb.git"]="c87990f46956c0703d809257fa3fc95ee58c41cf")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
