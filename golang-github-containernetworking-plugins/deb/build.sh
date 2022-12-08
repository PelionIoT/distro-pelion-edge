#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="golang-github-containernetworking-plugins"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

PELION_PACKAGE_BINARY_NAME="containernetworking-plugins-c2d"

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/containernetworking/plugins.git"]="v0.8.5")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
