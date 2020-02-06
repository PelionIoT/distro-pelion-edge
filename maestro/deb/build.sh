#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="maestro"
PELION_PACKAGE_VERSION="0.0.1" # The same value is in debian/control file
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

PELION_COMPONENT_NAME="maestro"
PELION_COMPONENT_URL="git@github.com:armPelionEdge/maestro.git"
PELION_COMPONENT_VERSION="d224292b87dd5d60fae4e24d746875e2c49c802d"

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

