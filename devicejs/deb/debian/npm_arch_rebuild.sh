#!/bin/bash

declare -A ARCH_MAP=( \
    ["amd64"]="x64"   \
    ["arm64"]="arm64" \
    ["armhf"]="arm")

NPM_ARCH=${ARCH_MAP["$1"]}

npm rebuild --production --target_arch=$NPM_ARCH --arch=$NPM_ARCH
