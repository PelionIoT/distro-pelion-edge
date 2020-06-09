#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="devicedb"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["git@github.com:armPelionEdge/devicedb.git"]="a4ee46f3d9bc58b694e7563502142dfe265110cb")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
