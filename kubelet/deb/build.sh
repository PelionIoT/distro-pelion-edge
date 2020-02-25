#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="kubelet"
PELION_PACKAGE_VERSION="0.0.1" # The same value is in debian/control file
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["git@github.com:armPelionEdge/argus.git"]="89ba7843747d9fc230cc06bc1f7d597e79ad56f8")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"