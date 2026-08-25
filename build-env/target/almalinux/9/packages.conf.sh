# AlmaLinux 9 target (also matches Rocky 9, RHEL 9 and CentOS Stream 9).
#
# Derived from target/rhel/8, with two differences:
#  1. No Red Hat subscription. The RHEL image registers with
#     subscription-manager only to unlock codeready-builder; AlmaLinux ships
#     that content as the free "crb" repo, so docker_image_create needs no
#     credentials and takes no RH_USERNAME/RH_PASSWORD build args.
#  2. pe-terminal is built here. It is absent from the rhel/8 list even though
#     it has both a spec and an rpm/build.sh.
#
# build dependencies
# variables are evaluated in selected environment (eg. docker)

PACKAGES=(
    'edge-proxy'
    'golang-github-containernetworking-plugins'
    'kubelet'
    'pe-terminal'
    'pe-utils'
)

# Deliberately not built for el9. build-all.sh stops at the first failure, so
# these stay out of PACKAGES to keep a full run green; re-add one once its
# blocker below is fixed upstream. Each was tried on AlmaLinux 9.8 first.
#
#   mbed-edge-core          glibc 2.34 defines PTHREAD_STACK_MIN as
#   mbed-edge-core-devmode  __sysconf(...) rather than a constant, and
#   mbed-edge-core-byocmode mbed-cloud-client's mbed-client-pal
#                           Configs/pal_config/Linux/Linux_default.h uses it
#                           inside #if, so cpp fails with "missing binary
#                           operator before token \"(\"". el8 has glibc 2.28
#                           where it is a constant. Needs an upstream fix or a
#                           patch in the spec.
#                           devmode additionally needs the gitignored
#                           mbed_cloud_dev_credentials.c (see Quickstart).
#
#   mbed-fcc                CMake 3.31 on el9 does not generate the target the
#                           spec builds: "No rule to make target
#                           'factory-configurator-client-example.elf'".
#                           Configure succeeds; only the build rule is missing.
#
#   mbed-edge-examples      BuildRequires python2, which RHEL 9 removed
#                           entirely. Porting to python3 is an upstream change.

DISTNAME=almalinux9

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
    case "$OS_ID" in
        almalinux | rocky | rhel | centos) [[ "$OS_VERSION_ID" =~ ^9 ]] ;;
        *) false ;;
    esac
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
function env_load {
    ARCH=${ARCH:-$(opt_current_arch)}
    export PATH=/usr/lib/pelion/bin:$PATH
}

function env_load_docker {
    # create local repo packages cache
    REPO_DIR="$ROOT_DIR"/build/repo/almalinux9_"$ARCH"
    DOCKER_VOLUMES=( "$REPO_DIR":/opt/repo )

    # create empty package repository
    if [ ! -d "$REPO_DIR" ]; then
        mkdir -m 0755 -p "$REPO_DIR"
        docker_image_run build createrepo /opt/repo
    fi
}

# create docker container
function docker_image_create {
    # as first arg anything will work as we have only one image type for this
    # build (no source/build flavours)

    ENVDIR=$(dirname ${BASH_SOURCE[0]})

    # No subscription credentials needed: crb and EPEL 9 are both public.
    docker_build_image $ENVDIR/Dockerfile.$ARCH
}


# get image name for current target - all prefixes will be added in
# different function - return just plain name
# arg1: image kind: build, source (can be ignored)
# env: ARCH
function docker_image_name {
    echo almalinux-9-"$ARCH"
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

# execute build for given package, handle docker if needed here
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
    run_command_build sudo dnf clean metadata
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
