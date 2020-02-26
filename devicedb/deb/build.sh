#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="devicedb"
PELION_PACKAGE_VERSION="0.0.1" # The same value is in debian/control file
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["git@github.com:armPelionEdge/devicedb.git"]="66859c16080c98dc4af5e75f3c093d0c9387e9b3")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
