#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="fog-proxy"
PELION_PACKAGE_VERSION="0.0.1" # The same value is in debian/control file
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["git@github.com:armPelionEdge/fog-proxy.git"]="fe33b2bc2570da514326937597d84343bf4febe6")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
