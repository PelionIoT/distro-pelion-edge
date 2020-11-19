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
        sudo apt-get update
        # use python3 by default if python is not installed
        if ! which python3 >/dev/null && ! which python2 >/dev/null; then
            echo "No python found, installing python3"
            TO_INSTALL="python3 python3-requests python3-click"
            PYTHONCMD=python3
        elif python --version 2>&1 | grep -q 'Python 2'; then
            # try to install python-requests and python-click for Python2
            # as we should use python2 if it was choosen. On failure we switch
            # to python3
            if ! sudo apt install -y python-requests python-click; then
                echo "Unable to install deps for python2, switching to python3"
                TO_INSTALL="python3 python3-requests python3-click"
                PYTHONCMD=python3
            else
                echo "Using python2 installation"
                TO_INSTALL=""
                PYTHONCMD=python2
            fi
        else
            echo "Python3 already installed; installing python3 deps"
            TO_INSTALL="python3-requests python3-click"
            PYTHONCMD=python3
        fi

        if [ ! -z "$TO_INSTALL" ]; then
            sudo apt install -y $TO_INSTALL
        fi
    fi

    PYTHONUSERBASE="$PELION_TMP_BUILD_DIR/" \
    $PYTHONCMD pal-platform/pal-platform.py -v deploy --target=x86_x64_NativeLinux_mbedtls generate
}

pelion_main "$@"
