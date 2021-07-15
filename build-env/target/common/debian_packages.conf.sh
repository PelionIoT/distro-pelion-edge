# build dependencies
DEPENDS=(
    'golang-providers/golang-virtual'
    'pe-nodejs'
)

PACKAGES=(
    'pe-nodejs'
    'edge-proxy'
    'global-node-modules'
    'kubelet'
    'maestro'
    'mbed-edge-core'
    'mbed-edge-core-devmode'
    'golang-github-containernetworking-plugins'
    'mbed-edge-examples'
    'mbed-fcc'
    'pe-utils'
)

METAPACKAGES=(
    'pelion-edge'
    'pelion-edge-base'
    'pelion-edge-container-orchestration'
    'pelion-edge-protocol-engine'
)

# false if $1 arch is not supported
function env_arch_supported {
    case $1 in
        amd64 | arm64 | armhf) true ;;
        *) false ;;
    esac
}

function env_load {
    ARCH=${ARCH:-$(opt_current_arch)}
    opt_deps_arch=( $ARCH )
}

function docker_pre_run {
    unset PLATFORM_ARCH
}

function debian_rebuild_packages_gz {
    run_command_build bash -c "cd /opt/apt-repo && \
        mkdir -p pe-dependencies/ && \
        dpkg-scanpackages --multiversion pe-dependencies | gzip >pe-dependencies/Packages.gz"
}

function env_load_docker {
    REPO_DIR="$ROOT_DIR"/build/repo/$ENV_OS_NAME
    DOCKER_VOLUMES+=( "$REPO_DIR":/opt/apt-repo )
    DOCKER_VOLUMES+=( /var/run/docker.sock:/var/run/docker.sock )

    # prepare repo directory with required files (eg Package.gz or similar)
    if [ ! -d "$REPO_DIR" ]; then
        mkdir -m 755 -p "$REPO_DIR"
        debian_rebuild_packages_gz
    fi
}

function docker_image_name {
    echo pelion-$ENV_OS_NAME-$1
}

function path_package_script {
    echo "$1/deb/build.sh"
}

# build callbacks
function run_source {
    local package="$1"
    shift
    local -a args=('--source')

    if $opt_install; then
        args+=('--install')
    fi

    if [ -n "$ARCH" ]; then
        args+=( --arch=$ARCH )
    fi

    run_command_source "$(path_package_script $package)" "${args[@]}" "$@"
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

    if [ -n "$ARCH" ]; then
        args+=( --arch=$ARCH )
    fi

    run_command_build "$(path_package_script $package)" "${args[@]}" "$@"
}

function run_verify {
    local package="$1"
    shift
    local -a args=('--verify')

    # use ARCH only for regular packages verification, meta does not use ARCH
    if [ -n "$ARCH" ] && [[ ! $package =~ ^metapackages/ ]] ; then
        args+=( --arch=$ARCH )
    fi

    run_command_build "$(path_package_script $package)" "${args[@]}"
}

# arg1: package name
function run_deploy_deps {
    local package=$1
    run_command_build bash -c "cp \$($(path_package_script $package) --arch=$ARCH --print-target) /opt/apt-repo/pe-dependencies/"

    # recreate repo packages
    debian_rebuild_packages_gz
}

function run_tar_build {
    run_command_source ./build-env/bin/deb2tar.sh --arch="$ARCH" --distro="$ENV_OS_NAME"
}

