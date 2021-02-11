#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="k3s"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/rancher/k3s.git"]="v1.20.4+k3s1")

source "${PELION_PACKAGE_DIR}/../../build-env/inc/build-common.sh"

pelion_main "$@"
