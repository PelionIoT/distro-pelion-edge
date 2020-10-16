#!/bin/sh

set -e

SCRIPT_DIR=$(cd "`dirname \"$0\"`" && pwd)
CTX_PATH="$SCRIPT_DIR"/../../
DOCKER_FILE_PATH="$CTX_PATH"/docker-debian-10-buster

docker build --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) \
    -t pelion-buster-build -f "$DOCKER_FILE_PATH/Dockerfile.build" "$CTX_PATH"

docker build \
    -t pelion-buster-source -f "$DOCKER_FILE_PATH/Dockerfile.source" "$CTX_PATH"
