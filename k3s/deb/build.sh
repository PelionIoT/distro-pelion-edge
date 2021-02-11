#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="k3s"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/rancher/k3s.git"]="21d1690d5da50135cf3a4b9ccd278b1d037d52cc")

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
