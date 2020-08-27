#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="maestro"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["git@github.com:armPelionEdge/maestro.git"]="300fcdf67616f4018f0f2b53db4b88c54a333e1b")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
