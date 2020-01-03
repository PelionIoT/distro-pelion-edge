#!/bin/bash

#NOTE: VERSION is static value, you can not change it at this stage
VERSION="0.9.0"

function parse_args() {
   for opt in "$@"; do
    case "$opt" in
            --help|-h)
                echo "Usage: $0 [Options]"
                echo "Options:"
                echo " --help,-h Print this message."
                echo ""
                echo "Default mode: $0 "
                exit 0
                ;;
        esac
    done
}

function source_get() {
    #Clone all sources
    git clone https://github.com/ARMmbed/mbed-edge-examples.git

    if [ $? -ne 0 ]; then
        echo "Error: can not clone https://github.com/ARMmbed/mbed-edge-examples.git"
        exit 1
    fi

    cd mbed-edge-examples/ && git checkout $VERSION

    if [ $? -ne 0 ]; then
        echo "Error: can not checkout to $VERSION"
        exit 1
    fi

    git submodule update --init --recursive
    cd ..

    #Generate tar with origin sources
    mv mbed-edge-examples mbed-edge-examples-$VERSION
    tar czf mbed-edge-examples_$VERSION.orig.tar.gz mbed-edge-examples-$VERSION
}

function dpkg_builder_build() {
    cp -r debian mbed-edge-examples-$VERSION

    if [ $? -ne 0 ]; then
        echo "Error: can not copy debian directory to mbed-edge-examples-$VERSION"
        exit 1
    fi

    cd mbed-edge-examples-$VERSION

    #Build deb packet
    dpkg-buildpackage -us -uc

    if [ $? -ne 0 ]; then
        echo "Error: can not build deb packet"
        exit 1
    fi
}

function main() {
    parse_args "$@"

    source_get

    dpkg_builder_build

    echo "INFO: Done!"
}

# ***** ENTRY POINT ******
main $@
