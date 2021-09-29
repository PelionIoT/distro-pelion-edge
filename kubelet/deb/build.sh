#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="kubelet"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/armPelionEdge/edge-kubelet.git"]="f8ebb1afd620f6a29691a21656a1bc3b54283906")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

string="$@"

if [[ $string == *"--arch=arm64"* ]]; then
    export OS_CPU="linux/arm64"
else
    if [[ $string == *"--arch=armhf"* ]]; then
        export OS_CPU="linux/arm"
    else
        export OS_CPU="linux/amd64"
    fi
fi

echo "buildtype=$OS_CPU"

pelion_main "$@"
