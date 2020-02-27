#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="fog-core"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["git@github.com:armPelionEdge/fog-core.git"]="5251afa5cfac4de73c25d2d38e9fd799f3f80f91")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
