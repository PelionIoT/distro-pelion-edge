#!/bin/bash

ROOT_DIR=$(cd "$(cd `dirname $0` && pwd)/../.."; pwd)

# Default value of build options
PELION_PACKAGE_INSTALL_DEPS=false
PELION_PACKAGE_TARGET_ARCH=amd64

if [[ ! -v PELION_PACKAGE_SUPPORTED_ARCH ]]; then
    PELION_PACKAGE_SUPPORTED_ARCH=(amd64 arm64 armhf armel)
fi

SOURCE_DIR=$ROOT_DIR/build/downloads
DEB_DEPLOY_DIR=$ROOT_DIR/build/deploy/deb
TMP_BUILD_DIR=$ROOT_DIR/build/tmp-build/$PELION_PACKAGE_NAME

function pelion_parse_args() {
   for opt in "$@"; do
        case "$opt" in
             --install)
                PELION_PACKAGE_INSTALL_DEPS=true
                ;;

             --arch=*)
                PELION_PACKAGE_TARGET_ARCH="${opt#*=}"
                ;;

              --cert_path=*)
                if [[ ! -v PELION_PACKAGE_CERTIFICATE_PATH ]]; then
                    echo "Error: --cert_path is invalid arg for $PELION_PACKAGE_NAME package."
                    exit 1
                fi
                PELION_PACKAGE_CERTIFICATE_PATH="${opt#*=}"
                ;;

            --help|-h)
                echo "Usage: $0 [Options]"
                echo ""
                echo "Options:"
                echo " --install           Install all dependencies needed by deb packet."
                echo " --arch=<arch>       Set target architecture."

                if [[ -v PELION_PACKAGE_CERTIFICATE_PATH ]]; then
                    echo " --cert_path=<path>  Path to mbed_cloud_dev_credentials.c."
                fi

                echo " --help,-h           Print this message."
                echo ""

                echo "Availiable architectures:"
                for arch in ${PELION_PACKAGE_SUPPORTED_ARCH[*]}
                do
                    echo "  $arch"
                done
                echo ""

                if [[ -v PELION_PACKAGE_CERTIFICATE_PATH ]]; then
                    echo "Default mode: $0 --arch=$PELION_PACKAGE_TARGET_ARCH --cert_path=$PELION_PACKAGE_CERTIFICATE_PATH"
                else
                    echo "Default mode: $0 --arch=$PELION_PACKAGE_TARGET_ARCH"
                fi
                exit 0
                ;;
        esac
    done
}

function pelion_env_validate() {
    for arch in "${PELION_PACKAGE_SUPPORTED_ARCH[@]}"; do
        if [[ $PELION_PACKAGE_TARGET_ARCH == "$arch" ]]; then
            break
        fi

        if [[ ${PELION_PACKAGE_SUPPORTED_ARCH[-1]} == "$arch" ]]; then
            echo "Error: Unsupported architecture: $PELION_PACKAGE_TARGET_ARCH."
            exit 1
        fi
    done

    if [[ -v PELION_PACKAGE_CERTIFICATE_PATH ]]; then
        if [ ! -f $PELION_PACKAGE_CERTIFICATE_PATH/mbed_cloud_dev_credentials.c ]; then
            echo "Error: $PELION_PACKAGE_CERTIFICATE_PATH/mbed_cloud_dev_credentials.c does not exist."
            exit 1
        fi
    fi
}

function pelion_source_preparation() {
    PELION_COMPONENT_NAME=$1
    PELION_COMPONENT_URL=$2
    PELION_COMPONENT_VERSION=$3

    if [ ! -d $SOURCE_DIR/$PELION_COMPONENT_NAME ]; then
        git clone $PELION_COMPONENT_URL $SOURCE_DIR/$PELION_COMPONENT_NAME

        if [ $? -ne 0 ]; then
            echo "Error: can not clone $PELION_COMPONENT_URL."
            exit 1
        fi
    fi

    cd $SOURCE_DIR/$PELION_COMPONENT_NAME && git remote update && \
    git checkout $PELION_COMPONENT_VERSION
    if [ $? -ne 0 ]; then
        echo "Error: can not checkout to $PELION_COMPONENT_VERSION."
        exit 1
    fi
}

function pelion_generation_deb_source_packages() {
    PELION_PACKAGE_FOLDER_NAME="$PELION_PACKAGE_NAME"-"$PELION_PACKAGE_VERSION"
    PELION_PACKAGE_ARCHIVE_NAME="$PELION_PACKAGE_NAME"_"$PELION_PACKAGE_VERSION"

    if [ ! -d $DEB_DEPLOY_DIR ]; then
        mkdir -p $DEB_DEPLOY_DIR
    fi

    if [ ! -d $TMP_BUILD_DIR ]; then
        mkdir -p $TMP_BUILD_DIR
    else
        rm -rf $TMP_BUILD_DIR/*
    fi

    cd $SOURCE_DIR
    tar czf $DEB_DEPLOY_DIR/$PELION_PACKAGE_ARCHIVE_NAME.orig.tar.gz $PELION_PACKAGE_NAME --exclude=.git --exclude=.github --exclude=.gitmodules --transform="s|$PELION_PACKAGE_NAME|$PELION_PACKAGE_FOLDER_NAME|"
    if [ $? -ne 0 ]; then
       echo "Error: can not archive $SOURCE_DIR/$PELION_PACKAGE_NAME to $DEB_DEPLOY_DIR/$PELION_PACKAGE_ARCHIVE_NAME.orig.tar.gz."
       exit 1
    fi

    tar xf $DEB_DEPLOY_DIR/$PELION_PACKAGE_ARCHIVE_NAME.orig.tar.gz -C $TMP_BUILD_DIR/
    cp -r $PELION_PACKAGE_DIR/debian $TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME

    cd $DEB_DEPLOY_DIR
    dpkg-source -b $TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME
    if [ $? -ne 0 ]; then
        echo "Error: can not generate deb source packages."
        exit 1
    fi
}

function pelion_building_deb_package() {
    PELION_PACKAGE_FOLDER_NAME="$PELION_PACKAGE_NAME"-"$PELION_PACKAGE_VERSION"
    PELION_PACKAGE_ARCHIVE_NAME="$PELION_PACKAGE_NAME"_"$PELION_PACKAGE_VERSION"

    if [ ! -d $DEB_DEPLOY_DIR ]; then
        mkdir -p $DEB_DEPLOY_DIR
    fi

    if [ ! -d $TMP_BUILD_DIR ]; then
        mkdir -p $TMP_BUILD_DIR
    else
        rm -rf $TMP_BUILD_DIR/*
    fi

    if $PELION_PACKAGE_INSTALL_DEPS ; then
        sudo apt-get update && \
        sudo apt-get build-dep -y -a $PELION_PACKAGE_TARGET_ARCH $DEB_DEPLOY_DIR/$PELION_PACKAGE_ARCHIVE_NAME-1.dsc
    fi

    if [ ! -f $DEB_DEPLOY_DIR/$PELION_PACKAGE_ARCHIVE_NAME.orig.tar.gz ] ||
       [ ! -f $DEB_DEPLOY_DIR/$PELION_PACKAGE_ARCHIVE_NAME-1.debian.tar.xz ]; then
        echo "Error: $DEB_DEPLOY_DIR/$PELION_PACKAGE_ARCHIVE_NAME.orig.tar.gz or $DEB_DEPLOY_DIR/$PELION_PACKAGE_ARCHIVE_NAME-1.debian.tar.xz not found."
        exit 1
    fi

    tar xf $DEB_DEPLOY_DIR/$PELION_PACKAGE_ARCHIVE_NAME.orig.tar.gz -C $TMP_BUILD_DIR/
    tar xf $DEB_DEPLOY_DIR/$PELION_PACKAGE_ARCHIVE_NAME-1.debian.tar.xz -C $TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME

    cd $TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME
    dpkg-buildpackage --host-arch $PELION_PACKAGE_TARGET_ARCH -b -uc
    if [ $? -ne 0 ]; then
        echo "Error: can not build deb packet."
        exit 1
    fi

    mv $TMP_BUILD_DIR/$PELION_PACKAGE_ARCHIVE_NAME-1_$PELION_PACKAGE_TARGET_ARCH.deb $DEB_DEPLOY_DIR
}
