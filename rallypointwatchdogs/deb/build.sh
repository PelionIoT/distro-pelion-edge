#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="rallypointwatchdogs"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/armPelionEdge/rallypointwatchdogs.git"]="54ee3bd50b063425606ad76aefad4167780d8760")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

pelion_main "$@"