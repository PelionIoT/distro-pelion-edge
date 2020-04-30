#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$0")
BASENAME=$(basename "$0")

PACKAGES=(
    'devicedb'
    'devicejs'
    'deviceoswd'
    'fog-core'
    'fog-proxy'
    'global-node-modules'
    'kubelet'
    'maestro'
    'maestro-shell'
    'mbed-devicejs-bridge'
    'mbed-edge-core'
    'mbed-edge-core-devmode'
    'mbed-edge-examples'
    'mbed-fcc'
    'pe-nodejs'
    'pe-utils'
    'rallypointwatchdogs'
)

METAPACKAGES=(
    'pelion-base'
    'pelion-base-devmode'
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

            --docker)
                PELION_PACKAGE_DOCKER=true
                ;;

            --help|-h)
                echo "Usage: $BASENAME [Options]"
                echo ""
                echo "Options:"
                echo " --source            Generate source package."
                echo " --build             Build binary from source generated with --source option."
                echo " --tar               Build a tarball from Debian packages."
                echo " --docker            Use docker containers."
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
        PELION_BUILD_OPT="--docker"
    fi
}

pelion_parse_args "$@"

if $PELION_PACKAGE_SOURCE; then
    for p in "${PACKAGES[@]}"; do
        echo "Generating source package of '$p'"
        "$SCRIPT_DIR"/../../"$p"/deb/build.sh $PELION_BUILD_OPT --source
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
    cd "$SCRIPT_DIR"/../..
    CONTAINER=pelion-bionic-source

    if $PELION_PACKAGE_DOCKER && [ -z "$(docker images -q $CONTAINER)" ]; then
        ./build-env/bin/docker-ubuntu-bionic-create.sh
    fi

    for arch in "${PELION_ARCHS[@]}"; do
        if $PELION_PACKAGE_DOCKER; then
            docker run --rm \
                -v "$HOME/.ssh":/home/user/.ssh \
                -v "$(pwd)":/pelion-build \
                $CONTAINER ./build-env/bin/deb2tar.sh --arch="$arch"
        else
            ./build-env/bin/deb2tar.sh --arch="$arch"
        fi
    done
fi
