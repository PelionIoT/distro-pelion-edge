#!/bin/sh
echo "WARNING: this script is deprecated. Use docker-run-env.sh instead"

ROOT_DIR=$(cd "`dirname \"$0\"`"/../.. && pwd)

DOCKER_DIST=$(echo $1 | cut -d- -f2)
APT_REPO="$ROOT_DIR"/build/apt/$DOCKER_DIST
echo "Using APT repo dir: " $APT_REPO
mkdir -p -m 755 $APT_REPO

if [ -n "$SSH_AUTH_SOCK" ]; then
	# Docker for Mac requires a magic string instead of the value of SSH_AUTH_SOCK - see https://github.com/docker/for-mac/issues/410#issuecomment-537127831
	[[ $OSTYPE == darwin* ]] && SSH_AUTH_SOCK_SRC=/run/host-services/ssh-auth.sock || SSH_AUTH_SOCK_SRC=$SSH_AUTH_SOCK
	if ssh-add -l >/dev/null 2>&1; then
		SSH_ARGS="-v $SSH_AUTH_SOCK_SRC:/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent"
	else
		echo "ssh-agent is running, but has no keys (run ssh-add to fix this). Falling back to .ssh mapping."
	fi
fi
if [ -z "$SSH_ARGS" ]; then
	SSH_ARGS="-v $HOME/.ssh:/home/user/.ssh"
fi

docker run -it \
    $SSH_ARGS \
    -v "$HOME":/mnt/home \
    -v "$ROOT_DIR":/pelion-build \
    -v "$APT_REPO":/opt/apt-repo \
	-v /var/run/docker.sock:/var/run/docker.sock \
    -ti "$@"
