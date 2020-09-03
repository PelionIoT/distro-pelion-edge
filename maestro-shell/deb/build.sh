#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="maestro-shell"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

#exported the branch so we can use it in auto_build script
export PACKAGE_BRANCH="2c90fbe2552c58ec5121b75a08718be6ebe5a791"

declare -A PELION_PACKAGE_COMPONENTS=(
    ["git@github.com:armPelionEdge/maestro-shell.git"]="$PACKAGE_BRANCH")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
