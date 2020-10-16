#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="mbed-fcc"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

PELION_PACKAGE_SKIP_DEPS_CHECKING=true
PELION_PACKAGE_ORIGIN_SOURCE_UPDATE_CALLBACK=pelion_mbed_fcc_origin_source_update_cb

declare -A PELION_PACKAGE_COMPONENTS=(
    ["https://github.com/ARMmbed/factory-configurator-client-example.git"]="master"
    ["https://github.com/ARMmbed/mbed-cloud-client.git"]="master")

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

function pelion_mbed_fcc_origin_source_update_cb() {
    mv "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/factory-configurator-client-example"/* "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"

    cd "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME" && \
    rm -rf factory-configurator-client-example

    if $PELION_PACKAGE_INSTALL_DEPS; then
    	sudo apt-get update && \
        # use python3 by default
        if python --version 2>&1 | grep -q 'Python 2'; then
            echo "Using python2..."
    	    sudo apt-get install -y python python-requests python-click
        else
            echo "Using python3..."
    	    sudo apt-get install -y python3 python3-requests python3-click
        fi
    fi

    PYTHONUSERBASE="$PELION_TMP_BUILD_DIR/" \
    python pal-platform/pal-platform.py -v deploy --target=Yocto_Generic_YoctoLinux_mbedtls generate
}

pelion_main "$@"
