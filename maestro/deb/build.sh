#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="maestro"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

PELION_PACKAGE_PRE_BUILD_CALLBACK='select_python 2'

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/armPelionEdge/maestro.git"]="20caa5d032424a11146b7923eaaed74e80de96da")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"
