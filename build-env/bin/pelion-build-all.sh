#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$0")
BASENAME=$(basename "$0")

PACKAGES=(
    'devicedb'
    'deviceoswd'
    'maestro'
    'maestro-shell'
    'mbed-devicejs-bridge'
    'mbed-edge-core'
    'mbed-edge-examples'
    'rallypointwatchdogs'
)

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

           --help|-h)
               echo "Usage: $BASENAME [Options]"
               echo ""
               echo "Options:"
               echo " --install           Install all dependencies needed by deb packets."
               echo " --arch=<arch>       Set comma-separated list of target architectures."
               echo " --help,-h           Print this message."
               echo ""

               exit 0
               ;;
        esac
    done
}

pelion_parse_args $@

for p in ${PACKAGES[@]}; do
    for arch in "${PELION_ARCHS[@]}"; do
        echo "Building '$p' for '$arch'"
        "$SCRIPT_DIR"/../../$p/deb/build.sh $PELION_BUILD_OPT --arch=$arch
    done
done

