#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="maestro-shell"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["git@github.com:armPelionEdge/maestro-shell.git"]="6961f98d2e95bde62ce26d0f18765ff523e09c2e")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
