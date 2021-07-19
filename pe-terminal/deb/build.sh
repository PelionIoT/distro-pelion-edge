#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="pe-terminal"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["git@github.com:PelionIoT/pe-terminal.git"]="8d2a020eb0bccf40cd9d9e54188e29df531bc019")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
