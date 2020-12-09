#!/bin/sh

ROOT_DIR=$(cd "`dirname \"$0\"`"/../.. && pwd)

DOCKER_DIST=$(echo $1 | cut -d- -f2)
APT_REPO="$ROOT_DIR"/build/apt/$DOCKER_DIST
echo "Using APT repo dir: " $APT_REPO
mkdir -p $APT_REPO

if [ -n "$SSH_AUTH_SOCK" ]; then
	SSH_ARGS="-v $SSH_AUTH_SOCK:/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent"
else
	SSH_ARGS="-v $HOME/.ssh:/home/user/.ssh"
fi

docker run -it \
    $SSH_ARGS \
    -v "$HOME":/mnt/home \
    -v "$ROOT_DIR":/pelion-build \
    -v "$APT_REPO":/opt/apt-repo \
    "$@"

