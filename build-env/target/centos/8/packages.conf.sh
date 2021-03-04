source $ENV_TARGET_ROOT/rhel/8/packages.conf.sh

DISTNAME=centos8

function env_match_current {
    [ "$OS_ID" == 'centos' ] && [[ "$OS_VERSION_ID" =~ ^8 ]]
}

function env_load_docker {
    # create local repo packages cache
    # TODO: do not run if there is cache already
    REPO_DIR="$ROOT_DIR"/build/repo/centos_"$ARCH"
    DOCKER_VOLUMES=( "$REPO_DIR":/opt/repo )

    # create empty package repository
    if [ ! -d "$REPO_DIR" ]; then
        mkdir -p "$REPO_DIR"
        docker_image_run build createrepo /opt/repo
    fi
}

# create docker container
function docker_image_create {
    # as first arg anything will work as we have only one image type for this build (no source/build flavours)
    # this uses defined below 'docker_image_name' function to build image name

    ENVDIR=$(dirname ${BASH_SOURCE[0]})

    docker_build_image $ENVDIR/Dockerfile.$ARCH
}


# get image name for current target - all prefixes will be added in
# different function - return just plain name
# eg: pelion-ubuntu-focal-source
# arg1: image kind: build, source (can be ignored)
# env: ARCH
function docker_image_name {
    # here we are using different image for different arch, but same for source
    # and build stages
    echo centos-8-"$ARCH"
}

