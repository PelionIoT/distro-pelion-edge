#!/bin/sh

set -e

SCRIPT_DIR=$(cd "`dirname \"$0\"`" && pwd)
CTX_PATH="$SCRIPT_DIR"/../docker
DOCKER_FILE_PATH="$CTX_PATH"/docker-ubuntu-20-focal

docker build --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) \
    -t pelion-focal-build -f "$DOCKER_FILE_PATH/Dockerfile.build" "$CTX_PATH"

docker build \
    -t pelion-focal-source -f "$DOCKER_FILE_PATH/Dockerfile.source" "$CTX_PATH"
