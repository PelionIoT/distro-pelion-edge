#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="devicedb"
PELION_PACKAGE_VERSION="0.0.1" # The same value is in debian/control file
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

PELION_COMPONENT_NAME="devicedb"
PELION_COMPONENT_URL="git@github.com:armPelionEdge/devicedb.git"
PELION_COMPONENT_VERSION="66859c16080c98dc4af5e75f3c093d0c9387e9b3"

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

function main() {
    pelion_parse_args "$@"

    pelion_env_validate

    pelion_source_preparation $PELION_COMPONENT_NAME $PELION_COMPONENT_URL $PELION_COMPONENT_VERSION
    echo "INFO: Source preparation done!"

    pelion_generation_deb_source_packages
    echo "INFO: Generation debian source packages done!"

    pelion_building_deb_package
    echo "INFO: Building debian package done!"

    echo "INFO: Done!"
}

# Entry point
main "$@"

