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
    'pe-utils'
    'rallypointwatchdogs'
)

PELION_PACKAGE_SOURCE=false
PELION_PACKAGE_BUILD=false
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

            --docker)
                PELION_PACKAGE_DOCKER=true
                ;;

            --help|-h)
                echo "Usage: $BASENAME [Options]"
                echo ""
                echo "Options:"
                echo " --source            Generate source package."
                echo " --build             Build binary from source generated with --source option."
                echo " --docker            Use docker containers."
                echo " --install           Install build dependencies."
                echo " --arch=<arch>       Set comma-separated list of target architectures."
                echo " --help,-h           Print this message."
                echo ""
                echo "If neither '--source' nor '--build' option is specified both are activated."
                echo ""

                exit 0
                ;;
        esac
    done

    if ! $PELION_PACKAGE_SOURCE && ! $PELION_PACKAGE_BUILD; then
        PELION_PACKAGE_SOURCE=true
        PELION_PACKAGE_BUILD=true
    fi

    if $PELION_PACKAGE_DOCKER; then
        # Overwrite 'install' option if it was provided. Docker build always
        # installs dependencies.
        PELION_BUILD_OPT="--docker"
    fi
}

pelion_parse_args $@

if $PELION_PACKAGE_SOURCE; then
    for p in ${PACKAGES[@]}; do
        echo "Generating source package of '$p'"
        "$SCRIPT_DIR"/../../$p/deb/build.sh $PELION_BUILD_OPT --source
    done
fi

if $PELION_PACKAGE_BUILD; then
    for arch in "${PELION_ARCHS[@]}"; do
        for p in ${PACKAGES[@]}; do
            echo "Building '$p' for '$arch'"
            "$SCRIPT_DIR"/../../$p/deb/build.sh $PELION_BUILD_OPT --arch=$arch --build
        done
    done
fi

