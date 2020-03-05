#!/bin/sh

ROOT_DIR=$(cd "`dirname \"$0\"`"/../.. && pwd)

docker run -it \
    -v "$HOME/.ssh":/home/user/.ssh \
    -v "$HOME":/mnt/home \
    -v "$ROOT_DIR":/pelion-build \
    "$@"

