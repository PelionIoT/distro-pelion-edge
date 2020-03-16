#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="pelion-container-orchestration"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

source "$PELION_PACKAGE_DIR"/../../../build-env/inc/build-common.sh

pelion_generation_deb_metapackage "$@"
