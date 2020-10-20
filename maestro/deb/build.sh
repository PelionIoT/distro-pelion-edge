#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="maestro"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["git@github.com:armPelionEdge/maestro.git"]="59d781b6b7cc4330889c45ac1aee8d713af6f22b")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
