# build dependencies
# variables are evaluated in selected environment (eg. docker)
DEPENDS=(
    'pe-nodejs'
)

PACKAGES=(
    'pe-nodejs'
    'edge-proxy'
    'global-node-modules'
    'golang-github-containernetworking-plugins'
    'kubelet'
    'maestro'
    'maestro-shell'
    'mbed-edge-core'
    'mbed-edge-core-devmode'
    'mbed-edge-examples'
    'mbed-fcc'
    'pe-utils'
)

DISTNAME=rhel8

#METAPACKAGES=(
#    'pelion-edge'
#    'pelion-edge-base'
#    'pelion-edge-container-orchestration'
#    'pelion-edge-protocol-engine'
#)


##########################################
# interface - to be implemented per ENV: #
##########################################
# return true if current environment is matching environment settigs
function env_match_current {
    [ "$OS_ID" == 'rhel' ] && [[ "$OS_VERSION_ID" =~ ^8 ]]
}

# false if $1 arch is not supported
function env_arch_supported {
    case $1 in
        amd64 | arm64) true ;;
        *) false ;;
    esac
}

# load environment - common for all architectures
# for non-host arch function calls set ARCH variable before
# TODO: this could change after adding support for amd64 in docker
#       we may need to call load_env each time ARCH changes
#       We would need env_pre_run call before running docker?
# TODO: rename env_load_for_docker? and call before docker_run
function env_load {
    # TODO: remove from here?
    ARCH=${ARCH:-$(opt_current_arch)}
    export PATH=/usr/lib/pelion/bin:$PATH
}

function env_load_docker {
    # create local repo packages cache
    # TODO: do not run if there is cache already
    REPO_DIR="$ROOT_DIR"/build/repo/rhel8_"$ARCH"
    DOCKER_VOLUMES=( "$REPO_DIR":/opt/repo )

    # create empty package repository
    if [ ! -d "$REPO_DIR" ]; then
        mkdir -m 0755 -p "$REPO_DIR"
        docker_image_run build createrepo /opt/repo
    fi
}

# create docker container
function docker_image_create {
    # as first arg anything will work as we have only one image type for this build (no source/build flavours)
    # this uses defined below 'docker_image_name' function to build image name

    ENVDIR=$(dirname ${BASH_SOURCE[0]})

    # ask for credentials, pass creds as env variables to Dockerfile
    # unset them after build
    [ ! -v RH_USERNAME ] && read -e -p "Red Hat Subscription username: " RH_USERNAME
    [ ! -v RH_PASSWORD ] && read -es -p "Red Hat Subscription password: " RH_PASSWORD
    export RH_USERNAME RH_PASSWORD
    local -a DOCKER_BUILD_ARGS=( RH_USERNAME RH_PASSWORD )

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
    echo redhat-8-"$ARCH"
}

# run source build
# arg1: package name
function run_source {
    local package="$1"
    shift
    local -a args=('--source')

    if $opt_install; then
        args+=('--install')
    fi

    run_command_build "$(path_package_script $package)" "${args[@]}" "$@"
}

function docker_pre_run {
    # set platform to ARCH - using QEMU
    PLATFORM_ARCH=linux/${ARCH}
}

# execute build for given package, handle docker if needed here (eg. packages
# does not support docker directly)
# pass required parameters (eg. --install --arch etc)
# arg1: package name
function run_build {
    local package="$1"
    shift
    local -a args=('--build')

    if $opt_install; then
        args+=('--install')
    fi

    run_command_build "$(path_package_script $package)" "${args[@]}" "$@"
}

function run_source_deps {
    run_source "$@" --deploy=/opt/repo
}

function run_build_deps {
    run_build "$@" --deploy=/opt/repo
}

# arg1: package name
function run_deploy_deps {
    # recreate repo packages
    run_command_build createrepo /opt/repo
    run_command_build sudo yum clean metadata
}

function run_tar_build {
    :
}

# return package build script path (relative to repo ROOT)
# arg1: package name
function path_package_script {
    echo "$1/rpm/build.sh"
}

# return path(s) to result of build for 'package name'
# arg1: package name
function path_package_result {
    ! :
}

