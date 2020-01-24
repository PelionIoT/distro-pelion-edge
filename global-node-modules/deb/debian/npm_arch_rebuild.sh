#!/bin/bash

declare -A ARCH_MAP=( \
    ["amd64"]="x64"   \
    ["arm64"]="arm64" \
    ["armhf"]="arm")

npm rebuild --target_arch=${ARCH_MAP["$1"]} ${@:2}
