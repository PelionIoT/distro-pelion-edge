#!/bin/sh

set -e

SCRIPT_DIR=$(cd "`dirname \"$0\"`" && pwd)
CTX_PATH="$SCRIPT_DIR"/../docker
DOCKER_FILE_PATH="$CTX_PATH"/docker-ubuntu-16-xenial

docker build --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) \
    -t ubuntu1604-clean -f "$DOCKER_FILE_PATH"/Dockerfile "$CTX_PATH"
