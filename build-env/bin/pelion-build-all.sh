#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$0")
BASENAME=$(basename "$0")
ROOT_DIR="$SCRIPT_DIR"/../..
source "${ROOT_DIR}"/build-env/docker/common/create-repo-lib.sh

DEPENDS=(
    'golang-providers/golang-virtual'
    'pe-nodejs'
)

PACKAGES=(
    'devicedb'
    'edge-proxy'
    'global-node-modules'
    'kubelet'
    'maestro'
    'maestro-shell'
    'mbed-edge-core'
    'mbed-edge-core-devmode'
    'golang-github-containernetworking-plugins'
    'mbed-edge-examples'
    'mbed-fcc'
    'pe-utils'
)

METAPACKAGES=(
    'pelion-base'
    'pelion-container-orchestration'
    'pelion-protocol-engine'
)

PELION_PACKAGE_SOURCE=false
PELION_PACKAGE_BUILD=false

PELION_TARBALL=false

PELION_PACKAGE_DOCKER=false
PELION_BUILD_OPT=''
PELION_ARCHS=( 'amd64' )

function pelion_parse_args() {
    for opt in "$@"; do
        case "$opt" in
            --install)
                PELION_BUILD_OPT+=' --install'
                ;;

            --arch=*)
                IFS=',' read -ra PELION_ARCHS <<< "${opt#*=}"
                ;;

            --build)
                PELION_PACKAGE_BUILD=true
                ;;

            --source)
                PELION_PACKAGE_SOURCE=true
                ;;

            --tar)
                PELION_TARBALL=true
                ;;

            --docker=*)
                PELION_PACKAGE_DOCKER=true
                local OPTARG=${opt#*=}
                DOCKER_DIST=${OPTARG:-bionic}
                ;;

            --help|-h)
                echo "Usage: $BASENAME [Options]"
                echo ""
                echo "Options:"
                echo " --source            Generate source package."
                echo " --build             Build binary from source generated with --source option."
                echo " --tar               Build a tarball from Debian packages."
                echo " --docker[=dist]     Use docker containers (dist can be focal, bionic, buster...)."
                echo " --install           Install build dependencies."
                echo " --arch=<arch>       Set comma-separated list of target architectures."
                echo " --help,-h           Print this message."
                echo ""
                echo "If none of '--source', '--build' or '--tar' options are specified,"
                echo "all of them are activated."
                echo ""

                exit 0
                ;;
        esac
    done
    if ! $PELION_PACKAGE_SOURCE && ! $PELION_PACKAGE_BUILD && ! $PELION_TARBALL; then
        PELION_PACKAGE_SOURCE=true
        PELION_PACKAGE_BUILD=true

        PELION_TARBALL=true
    fi

    if $PELION_PACKAGE_DOCKER; then
        # Overwrite 'install' option if it was provided. Docker build always
        # installs dependencies.
        PELION_BUILD_OPT="--docker=$DOCKER_DIST"
    fi
}

pelion_parse_args "$@"

BUILD_DEPS=true
if $BUILD_DEPS; then
    # TODO when --install or --docker is set only
    # Create repository dir if needed:
    # - for in-docker run - use APT_REPO_PATH
    # - for out-of-docker: use apt/$CONTAINER-apt
    # - for no container: use apt
    # TODO: if --docker
    APT_REPO_PATH=$ROOT_DIR/build/apt/$DOCKER_DIST
    # TODO: else
    # APT_REPO_PATH=${APT_REPO_PATH:-$ROOT_DIR/build/apt}
    # if --install
    # apt_create_trusted_repo $APT_REPO_NAME
    # fi
    APT_REPO_NAME=pe-dependencies
    mkdir -p $APT_REPO_PATH/$APT_REPO_NAME

    # Create packages in target repository - empty required to not fail the build
    (cd $APT_REPO_PATH && dpkg-scanpackages --multiversion $APT_REPO_NAME | gzip >$APT_REPO_NAME/Packages.gz)

	# Deps build
    for arch in "${PELION_ARCHS[@]}"; do
        for p in "${DEPENDS[@]}"; do
            echo "Building '$p' for '$arch'"
            "$SCRIPT_DIR"/../../"$p"/deb/build.sh $PELION_BUILD_OPT --arch="$arch" --source --build
        done
    done

    # Install deps to local repo
    for arch in "${PELION_ARCHS[@]}"; do
        for p in "${DEPENDS[@]}"; do
            echo "Installing '$p' for '$arch'"
            echo "$ROOT_DIR"/"$p"/deb/build.sh $PELION_BUILD_OPT --arch="$arch" --print-target
            TARGET_PACKAGE=$("$ROOT_DIR"/"$p"/deb/build.sh $PELION_BUILD_OPT --arch="$arch" --print-target)
            cp -f $TARGET_PACKAGE $APT_REPO_PATH/$APT_REPO_NAME
        done
    done

    # Create packages in target repository
    (cd $APT_REPO_PATH && dpkg-scanpackages --multiversion $APT_REPO_NAME | gzip >$APT_REPO_NAME/Packages.gz)
fi

if $PELION_PACKAGE_SOURCE; then
    for p in "${PACKAGES[@]}"; do
        echo "Generating source package of '$p'"
        if [ "$p" == "pe-nodejs" ]; then
            # pe-nodejs is just a debian package of pre-built # source.
            # We need to pass the arch here so we know what binary tarball
            # architecture to download.
            for arch in "${PELION_ARCHS[@]}"; do
                "$SCRIPT_DIR"/../../"$p"/deb/build.sh $PELION_BUILD_OPT --arch="$arch" --source
            done
        else
            "$SCRIPT_DIR"/../../"$p"/deb/build.sh $PELION_BUILD_OPT --source
        fi
    done
fi

if $PELION_PACKAGE_BUILD; then
    # Build
    for arch in "${PELION_ARCHS[@]}"; do
        for p in "${PACKAGES[@]}"; do
            echo "Building '$p' for '$arch'"
            "$SCRIPT_DIR"/../../"$p"/deb/build.sh $PELION_BUILD_OPT --arch="$arch" --build
        done
    done

    for p in "${METAPACKAGES[@]}"; do
        echo "Generating '$p'"
        "$SCRIPT_DIR"/../../metapackages/"$p"/deb/build.sh $PELION_BUILD_OPT --build
    done

    #Verify
    for arch in "${PELION_ARCHS[@]}"; do
        for p in "${PACKAGES[@]}"; do
            echo "Verifying '$p' for '$arch'"
            "$SCRIPT_DIR"/../../"$p"/deb/build.sh $PELION_BUILD_OPT --arch="$arch" --verify
        done
    done

    for p in "${METAPACKAGES[@]}"; do
        echo "Verifying '$p'"
        "$SCRIPT_DIR"/../../metapackages/"$p"/deb/build.sh $PELION_BUILD_OPT --verify
    done
fi

if $PELION_TARBALL; then
    cd $ROOT_DIR
    CONTAINER=pelion-$DOCKER_DIST-source

    if $PELION_PACKAGE_DOCKER && [ -z "$(docker images -q $CONTAINER)" ]; then
        # TODO: do not use * here
        ./build-env/bin/docker-*-$CONTAINER-create.sh
    fi

    for arch in "${PELION_ARCHS[@]}"; do
        if $PELION_PACKAGE_DOCKER; then
            docker run --rm \
                -v "$HOME/.ssh":/home/user/.ssh \
                -v "$ROOT_DIR":/pelion-build \
                $CONTAINER ./build-env/bin/deb2tar.sh --arch="$arch"
        else
            ./build-env/bin/deb2tar.sh --arch="$arch"
        fi
    done
fi
