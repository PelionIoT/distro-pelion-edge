#!/bin/bash

#NOTE: VERSION is static value, you can not change it at this stage
VERSION="0.10.0"

CERTIFICATE_PATH=$(pwd)

function parse_args() {
   for opt in "$@"; do
        case "$opt" in
             --path=*)
                CERTIFICATE_PATH="${opt#*=}"
                ;;

            --help|-h)
                echo "Usage: $0 [Options]"
                echo "Options:"
                echo " --path=<path>  Path to mbed_cloud_dev_credentials.c and update_default_resources.c"
                echo " --help,-h      Print this message."
                echo ""
                echo "Default mode: $0 --path=$(pwd)"
                exit 0
                ;;
        esac
    done
}

function source_get() {
    #Clone all sources
    git clone https://github.com/ARMmbed/mbed-edge.git

    if [ $? -ne 0 ]; then
        echo "Error: can not clone https://github.com/ARMmbed/mbed-edge.git"
        exit 1
    fi

    cd mbed-edge/ && git checkout $VERSION

    if [ $? -ne 0 ]; then
        echo "Error: can not checkout to $VERSION"
        exit 1
    fi

    git submodule update --init --recursive
    cd ..

    cp $CERTIFICATE_PATH/mbed_cloud_dev_credentials.c mbed-edge/config/

    #Generate tar with origin sources
    mv mbed-edge mbed-edge-core-$VERSION
    tar czf mbed-edge-core_$VERSION.orig.tar.gz mbed-edge-core-$VERSION
}


function dpkg_builder_build() {
    cp -r debian mbed-edge-core-$VERSION

    if [ $? -ne 0 ]; then
        echo "Error: can not copy debian directory to mbed-edge-core-$VERSION"
        exit 1
    fi

    cd mbed-edge-core-$VERSION

    #Build deb packet
    dpkg-buildpackage -us -uc

    if [ $? -ne 0 ]; then
        echo "Error: can not build deb packet"
        exit 1
    fi
}

function main() {
    parse_args "$@"

    if [ ! -f $CERTIFICATE_PATH/mbed_cloud_dev_credentials.c ]; then
        echo "Error: $CERTIFICATE_PATH/mbed_cloud_dev_credentials.c does not exist"
        exit 1
    fi

    source_get

    dpkg_builder_build

    echo "INFO: Done!"
}

# ***** ENTRY POINT ******
main $@
