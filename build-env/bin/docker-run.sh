#!/bin/sh

ROOT_DIR=$(cd "`dirname \"$0\"`"/../.. && pwd)

DOCKER_DIST=$(echo $1 | cut -d- -f2)
APT_REPO="$ROOT_DIR"/build/apt/$DOCKER_DIST
echo "Using APT repo dir: " $APT_REPO
mkdir -p $APT_REPO

docker run -it \
    -v "$HOME/.ssh":/home/user/.ssh \
    -v "$HOME":/mnt/home \
    -v "$ROOT_DIR":/pelion-build \
    -v "$APT_REPO":/opt/apt-repo \
    "$@"

