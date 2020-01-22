#!/bin/bash

# Default value of build options
INSTALL_DEPS=false
VERSION="0.10.0"
TARGET_ARCH="amd64"
CERTIFICATE_PATH=$(cd `dirname $0` && pwd)

# Internal variables
PACKAGE_VERSION="0.1.0"

COMPONENT_NAME="mbed-edge-core"
COMPONENT_URL="https://github.com/ARMmbed/mbed-edge.git"

PACKAGE_NAME="$COMPONENT_NAME"-"$PACKAGE_VERSION"
ARCHIVE_NAME="$COMPONENT_NAME"_"$PACKAGE_VERSION"

ROOT_DIR=$(cd "$(cd `dirname $0` && pwd)/../.."; pwd)
PACKAGE_DIR=$(cd `dirname $0` && pwd)

SOURCE_DIR=$ROOT_DIR/build/downloads
DEB_DEPLOY_DIR=$ROOT_DIR/build/deploy/deb
TMP_BUILD_DIR=$ROOT_DIR/build/tmp-build

function parse_args() {
   for opt in "$@"; do
        case "$opt" in
             --install)
                INSTALL_DEPS=true
                ;;

             --version=*)
                VERSION="${opt#*=}"
                ;;

             --arch=*)
                TARGET_ARCH="${opt#*=}"
                ;;

             --path=*)
                CERTIFICATE_PATH="${opt#*=}"
                ;;

            --help|-h)
                echo "Usage: $0 [Options]"
                echo "Options:"
                echo " --install           Install all dependencies needed by deb packet."
                echo " --version=<version> Set branch/tag/commit which will be packed."
                echo " --arch=<arch>       Set target architecture."
                echo " --path=<path>       Path to mbed_cloud_dev_credentials.c and update_default_resources.c."
                echo " --help,-h           Print this message."
                echo ""
                echo "Availiable architectures:"
                echo "   amd64 for Ubuntu 16.04, Ubuntu 18.04, Debian 9"
                echo "   arm64 for Ubuntu 16.04, Ubuntu 18.04, Debian 9"
                echo "   armhf for Ubuntu 16.04, Ubuntu 18.04, Debian 9"
                echo "   armel for Debian 9"
                echo ""
                echo "Default mode: $0 --version=0.10.0 --arch=amd64 --path=$(cd `dirname $0` && pwd)"
                exit 0
                ;;
        esac
    done
}

function source_preparation() {
    if [ ! -d $SOURCE_DIR/$COMPONENT_NAME ]; then
        git clone $COMPONENT_URL $SOURCE_DIR/$COMPONENT_NAME

        if [ $? -ne 0 ]; then
            echo "Error: can not clone $COMPONENT_URL."
            exit 1
        fi
    fi

    cd $SOURCE_DIR/$COMPONENT_NAME && git checkout $VERSION
    if [ $? -ne 0 ]; then
        echo "Error: can not checkout to $VERSION."
        exit 1
    fi

    git submodule update --init --recursive
    cp $CERTIFICATE_PATH/mbed_cloud_dev_credentials.c $SOURCE_DIR/$COMPONENT_NAME/config/

    echo "INFO: Source preparation done!"
}

function generation_deb_source_packages() {
    if [ ! -d $DEB_DEPLOY_DIR ]; then
        mkdir -p $DEB_DEPLOY_DIR
    fi

    cd $SOURCE_DIR
    tar czf $DEB_DEPLOY_DIR/$ARCHIVE_NAME.orig.tar.gz $COMPONENT_NAME --exclude .git --exclude .github --exclude .gitmodules --transform="s|$COMPONENT_NAME|$PACKAGE_NAME|"
    if [ $? -ne 0 ]; then
       echo "Error: can not archive $SOURCE_DIR/$COMPONENT_NAME to $DEB_DEPLOY_DIR/$ARCHIVE_NAME.orig.tar.gz."
       exit 1
    fi

    if [ ! -d $TMP_BUILD_DIR ]; then
        mkdir -p $TMP_BUILD_DIR
    else
        rm -rf $TMP_BUILD_DIR/$COMPONENT_NAME*
    fi

    tar xf $DEB_DEPLOY_DIR/$ARCHIVE_NAME.orig.tar.gz -C $TMP_BUILD_DIR/
    cp -r $PACKAGE_DIR/debian $TMP_BUILD_DIR/$PACKAGE_NAME

    cd $DEB_DEPLOY_DIR
    dpkg-source -b $TMP_BUILD_DIR/$PACKAGE_NAME
    if [ $? -ne 0 ]; then
        echo "Error: can not generate deb source packages."
        exit 1
    fi

    rm -rf $TMP_BUILD_DIR/$PACKAGE_NAME
    echo "INFO: Generation debian source packages done!"
}

function building_deb_package() {
    if $INSTALL_DEPS ; then
        sudo apt-get build-dep -y -a $TARGET_ARCH  $DEB_DEPLOY_DIR/$ARCHIVE_NAME-1.dsc
    fi

    if [ ! -d $TMP_BUILD_DIR ]; then
        mkdir -p $TMP_BUILD_DIR
    fi

    tar xf $DEB_DEPLOY_DIR/$ARCHIVE_NAME.orig.tar.gz -C $TMP_BUILD_DIR/
    tar xf $DEB_DEPLOY_DIR/$ARCHIVE_NAME-1.debian.tar.xz -C $TMP_BUILD_DIR/$PACKAGE_NAME

    cd $TMP_BUILD_DIR/$PACKAGE_NAME
    dpkg-buildpackage --host-arch $TARGET_ARCH -b -uc
    if [ $? -ne 0 ]; then
        echo "Error: can not build deb packet."
        exit 1
    fi

    cp $TMP_BUILD_DIR/$ARCHIVE_NAME-1_$TARGET_ARCH.deb $DEB_DEPLOY_DIR
    echo "INFO: Building debian package done!"
}

function main() {
    parse_args "$@"

    if [ $TARGET_ARCH != "amd64" ] &&
       [ $TARGET_ARCH != "arm64" ] &&
       [ $TARGET_ARCH != "armhf" ] &&
       [ $TARGET_ARCH != "armel" ]; then
        echo "Error: Unsupported architecture: $TARGET_ARCH."
        exit 1
    fi

    if [ ! -f $CERTIFICATE_PATH/mbed_cloud_dev_credentials.c ]; then
        echo "Error: $CERTIFICATE_PATH/mbed_cloud_dev_credentials.c does not exist."
        exit 1
    fi

    source_preparation

    generation_deb_source_packages

    building_deb_package

    echo "INFO: Done!"
}

# Entry point
main $@
