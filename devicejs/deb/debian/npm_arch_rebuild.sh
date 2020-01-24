#!/bin/bash

declare -A ARCH_MAP=( \
    ["amd64"]="x64"   \
    ["arm64"]="arm64" \
    ["armhf"]="arm")

npm rebuild --production --target_arch=${ARCH_MAP["$1"]}