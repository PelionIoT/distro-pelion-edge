#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="pelion-edge-protocol-engine"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

source "$PELION_PACKAGE_DIR"/../../../build-env/inc/build-common.sh

pelion_metapackage_main "$@"
