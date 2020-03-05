#!/bin/sh

SCRIPT_DIR=$(cd "`dirname \"$0\"`" && pwd)
CTX_PATH="$SCRIPT_DIR"/../docker/docker-ubuntu-18-bionic

docker build --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) \
    -t pelion-bionic-build -f "$CTX_PATH/Dockerfile.build" "$CTX_PATH"

docker build \
    -t pelion-bionic-source -f "$CTX_PATH/Dockerfile.source" "$CTX_PATH"
