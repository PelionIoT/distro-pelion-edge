
# uses ENV:
# - DOCKER - docker executable
# - DOCKER_VOLUMES - array of a:b volume mappings for docker run
# - PELION_DOCKER_PREFIX - prefix for created docker image

###########################################
# interface - to be implemented per target
function docker_image_create { :; }

# get image name for current target - all prefixes will be added in
# different function - return just plain name
# eg: pelion-ubuntu-focal-source
# arg1: image kind: build, source (can be ignored)
function docker_image_name { :; }

# Function called before 'docker run' and 'docker build' commands.
# Set PLATFORM_ARCH env variable for docker calls required for multiarch images.
# this will set --platform=$PLATFORM_ARCH in docker build and run.
# Variable required for RHEL (as uses QEMU), for cross-compilation - use host architecture
# or leave empty
function docker_pre_run { :; }
##########################################

# common
DOCKER=${DOCKER:-docker}
DOCKER_VOLUMES=( ${DOCKER_VOLUMES:-} )

# takes 'docker_image_name' output and adds prefix if needed
# this function should be used instead of calling docker_image_name
# directly
# arg1-N: passed to docker_image_name
function docker_image_name_processed {
    echo ${PELION_DOCKER_PREFIX:-}$(docker_image_name "$@")
}

# docker container image name for 'build' or 'source'
# arg1: build or source
function docker_container_name_processed {
    local image=$(docker_image_name_processed $1)
    echo ${image//[:]/_}
}

# run command in docker container. Passes SSH_AUTH_SOCK
# if present, otherwise mounts .ssh dir in the container
# adds $DOCKER_OPTS to docker run call (after 'run')
# arg1-N: argument passed to docker run call (last args)
function docker_image_run_generic {
    local kind="$1"
    shift

    docker_image_ensure_created "$kind"

    local DOCKER_COMMAND=run
    docker_image_call_generic "$(docker_image_name_processed $kind)" "$@"
}

# create or run container
# arg1-N: args to docker call
# env:
# - DOCKER - docker command
# - SSH_AUTH_SOCK - ssh auth socker (optional)
# - DOCKER_COMMAND - run or create
# - DOCKER_VOLUMES - list of a:b pairs to mount volumens inside container
# - PLATFORM_ARCH - --platform=$PLATFORM_ARCH arg passed to docker if set
function docker_image_call_generic {
    if [ -n "$SSH_AUTH_SOCK" ]; then
        SSH_ARGS="-v $SSH_AUTH_SOCK:/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent"
    else
        SSH_ARGS="-v $HOME/.ssh:/home/user/.ssh"
    fi

    docker_pre_run

    $DOCKER $DOCKER_COMMAND $DOCKER_OPTS \
        $SSH_ARGS \
        ${PLATFORM_ARCH:+--platform=$PLATFORM_ARCH} \
        -v "$HOME":/mnt/home \
        -v "$ROOT_DIR":/pelion-build \
        ${DOCKER_VOLUMES[@]/#/-v } \
        "$@"
}

# run in new container, keep container after execution
# arg1: passed to docker_image_name callback
# arg2-N: command to run
function docker_image_run_keep {
    local DOCKER_OPTS=""
    docker_image_run_generic "$@"
}

# run in temporary container (remove after execution)
# arg1: passed to docker_image_name callback
# arg2-N: command to run
# env:
# - DOCKER_OPTS - adds --rm to current DOCKER_OPTS
function docker_image_run {
    local DOCKER_OPTS="${DOCKER_OPTS} --rm"
    docker_image_run_generic "$@"
}

# check if docker image is already created
# arg1: argument passed to 'docker_image_name' (source or build)
function docker_image_available {
    [ -n "$($DOCKER images -q $(docker_image_name_processed $1))" ]
}

# check if docker image is already created
# arg1-N: source or build - passed to 'docker_image_name' callback
function docker_image_ensure_created {
    if ! docker_image_available "$@"; then
        docker_image_create "$@"
    fi
}


#######################
# container functions #
#######################

# create docker container, works same as 'docker_image_run_generic'
# but only creates container
# arg1-N: arguments passed to the docker create call
function docker_container_create_generic {
    local DOCKER_COMMAND=create
    docker_image_call_generic "$@"
}

# check if container is on containers list
# arg1: source, build
function docker_container_check {
    [ -n "$($DOCKER container ls $DOCKER_OPTS -fname=^$(docker_container_name_processed $1)$ -q)" ]
}

# check if docker container is already created
# arg1: source, build
function docker_container_available {
    local DOCKER_OPTS=-a
    docker_container_check $1
}

# check if container is started
# arg1: source, build
function docker_container_started {
    local DOCKER_OPTS=
    docker_container_check $1
}

# create container, do not start
# arg1: source, build
function docker_container_ensure_created {
    if ! docker_container_available "$1"; then
        local image_name=$(docker_image_name_processed "$1")
        local container_name=$(docker_container_name_processed "$1")

        docker_container_create_generic -it --name "$container_name" "$image_name" bash
    fi
}

# remove docker image (do not fail when missing)
# arg1: source, build
function docker_image_remove {
    # exit if no image
    if ! docker_image_available "$1"; then
        return 0
    fi

    # stop and remove containers before removing image
    if docker_container_available "$1"; then
        docker_container_remove "$1"
    fi

    $DOCKER rmi $(docker_image_name_processed "$1")
}

# remove container by name, stop if needed
# arg1: source, build
function docker_container_remove {
    if docker_container_started "$1"; then
        $DOCKER stop $(docker_container_name_processed "$1")
    fi

    $DOCKER rm $(docker_container_name_processed "$1")
}

# start container by kind name
# arg1: source or build
function docker_container_start {
    $DOCKER start $(docker_container_name_processed "$1")
}

# run command in started container
# arg1: source or build
# arg2-N: command to run in the container
# env:
# - DOCKER_OPTS - add opts to 'exec' command
function docker_container_exec {
    local CONTAINER=$1
    shift

    $DOCKER exec -it $DOCKER_OPTS $(docker_container_name_processed "$CONTAINER") "$@"
}

# run in docker container
# arg1-N: same as docker_image_run
function docker_container_run {
    if ! docker_container_started "$1"; then
        docker_image_ensure_created "$1"
        docker_container_ensure_created "$1"
        docker_container_start "$1"
    fi

    docker_container_exec "$@"
}

##########################
# docker build functions #
##########################

# build docker image
# NOTE: --pull flag required to workaround multiarch issue
#
# arg1: Dockerfile
# arg2: image type: build or source (to resolve image name)
# ENV:
# - CTX_PATH - build context root directory, default: ENV_TARGET_ROOT, or Dockerfile directory if ENV_TARGET_ROOT was not set
# - ENV_TARGET_ROOT - build context if CTX_PATH is not set
# - PELION_DOCKER_PREFIX - prefix to image name (passed as PREFIX arg to the build instance)
# - DOCKER_BUILD_ARGS - list build arguments (will prepend --build-arg on each element)
# - PLATFORM_ARCH - --platform=$PLATFORM_ARCH passed to docker if set
#
# Dockerfile args provided by this function:
# - USER_ID
# - GROUP_ID
# - PREFIX
function docker_build_image {
    local CTX_PATH=${CTX_PATH:-${ENV_TARGET_ROOT:-$(dirname $(realpath $1))}}

    docker_pre_run

    $DOCKER build   --build-arg USER_ID=$(id -u) \
                    --build-arg GROUP_ID=$(id -g) \
                    --build-arg PREFIX=$PELION_DOCKER_PREFIX \
                    --pull \
                    ${PLATFORM_ARCH:+--platform=$PLATFORM_ARCH} \
                    $(echo "${DOCKER_BUILD_ARGS[@]/#/--build-arg }" ) \
                    -t $(docker_image_name_processed $2) \
                    -f "$1" \
                    "$CTX_PATH"
}

