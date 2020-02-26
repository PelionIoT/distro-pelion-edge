#!/bin/bash

set -e -u

ROOT_DIR=$(cd "`dirname \"$0\"`"/../.. && pwd)

PELION_SOURCE_DIR=$ROOT_DIR/build/downloads
PELION_DEB_DEPLOY_DIR=$ROOT_DIR/build/deploy/deb
PELION_TMP_BUILD_DIR=$ROOT_DIR/build/tmp-build/$PELION_PACKAGE_NAME

# Default value of build options
PELION_PACKAGE_INSTALL_DEPS=false
PELION_PACKAGE_TARGET_ARCH=amd64

if [[ ! -v PELION_PACKAGE_SUPPORTED_ARCH ]]; then
    PELION_PACKAGE_SUPPORTED_ARCH=(amd64 arm64 armhf armel)
fi

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
        if [ ! -f "$PELION_PACKAGE_CERTIFICATE_PATH"/mbed_cloud_dev_credentials.c ]; then
            echo "Error: $PELION_PACKAGE_CERTIFICATE_PATH/mbed_cloud_dev_credentials.c does not exist."
            exit 1
        fi
    fi
}

function pelion_source_preparation() {
    for COMPONENT in "${!PELION_PACKAGE_COMPONENTS[@]}"; do
        PACKAGE_COMPONENT_BASENAME=$(basename $COMPONENT)
        PACKAGE_COMPONENT_FILENAME=${PACKAGE_COMPONENT_BASENAME%.*}

        if [ ! -d "$PELION_SOURCE_DIR/$PACKAGE_COMPONENT_FILENAME" ]; then
            git clone $COMPONENT "$PELION_SOURCE_DIR/$PACKAGE_COMPONENT_FILENAME"
        fi

        if [ ! ${PELION_PACKAGE_COMPONENTS[$COMPONENT]} ]; then
            PELION_PACKAGE_COMPONENTS[$COMPONENT]=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
        fi

        cd "$PELION_SOURCE_DIR/$PACKAGE_COMPONENT_FILENAME"        && \
        git remote update                                          && \
        git checkout ${PELION_PACKAGE_COMPONENTS[$COMPONENT]}
    done


    if [ -v PELION_PACKAGE_SOURCE_PREPARATION_CALLBACK ]; then
        $PELION_PACKAGE_SOURCE_PREPARATION_CALLBACK
    fi
}

function pelion_generation_deb_source_packages() {
    PELION_PACKAGE_FOLDER_NAME="$PELION_PACKAGE_NAME"-"$PELION_PACKAGE_VERSION"
    PELION_PACKAGE_ARCHIVE_NAME="$PELION_PACKAGE_NAME"_"$PELION_PACKAGE_VERSION"

    mkdir -p "$PELION_DEB_DEPLOY_DIR"

    rm -rf "$PELION_TMP_BUILD_DIR"
    mkdir -p "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"

    for COMPONENT in "${!PELION_PACKAGE_COMPONENTS[@]}"; do
        PACKAGE_COMPONENT_BASENAME=$(basename $COMPONENT)
        PACKAGE_COMPONENT_FILENAME=${PACKAGE_COMPONENT_BASENAME%.*}

        if [ ${#PELION_PACKAGE_COMPONENTS[@]} -gt 1 ]; then
            cp -r "$PELION_SOURCE_DIR/$PACKAGE_COMPONENT_FILENAME" "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/"

            rm -rf "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/$PACKAGE_COMPONENT_FILENAME/.git" \
                   "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/$PACKAGE_COMPONENT_FILENAME/.github"
        else
            cp -r "$PELION_SOURCE_DIR/$PACKAGE_COMPONENT_FILENAME/." "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/"

            rm -rf "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/.git" \
                   "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/.github"
        fi
    done

    if [ -v PELION_PACKAGE_ORIGIN_SOURCE_UPDATE_CALLBACK ]; then
        $PELION_PACKAGE_ORIGIN_SOURCE_UPDATE_CALLBACK
    fi

    tar czf "$PELION_DEB_DEPLOY_DIR/$PELION_PACKAGE_ARCHIVE_NAME.orig.tar.gz" -C "$PELION_TMP_BUILD_DIR" "$PELION_PACKAGE_FOLDER_NAME"
    cp -r "$PELION_PACKAGE_DIR/debian" "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"

    cd "$PELION_DEB_DEPLOY_DIR" && \
    dpkg-source -b "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"
}

function pelion_building_deb_package() {
    PELION_PACKAGE_FOLDER_NAME="$PELION_PACKAGE_NAME"-"$PELION_PACKAGE_VERSION"
    PELION_PACKAGE_ARCHIVE_NAME="$PELION_PACKAGE_NAME"_"$PELION_PACKAGE_VERSION"

    mkdir -p "$PELION_DEB_DEPLOY_DIR"

    rm -rf "$PELION_TMP_BUILD_DIR"
    mkdir -p "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"

    if $PELION_PACKAGE_INSTALL_DEPS; then
        sudo apt-get update && \
        sudo apt-get build-dep -y -a "$PELION_PACKAGE_TARGET_ARCH" "$PELION_DEB_DEPLOY_DIR/$PELION_PACKAGE_ARCHIVE_NAME.dsc"
    fi

    tar xf "$PELION_DEB_DEPLOY_DIR/$PELION_PACKAGE_ARCHIVE_NAME.orig.tar.gz" -C "$PELION_TMP_BUILD_DIR/"
    tar xf "$PELION_DEB_DEPLOY_DIR/$PELION_PACKAGE_ARCHIVE_NAME.debian.tar.xz" -C "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"

    cd "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"

    PELION_DPKG_BUILD_OPTIONS="--host-arch $PELION_PACKAGE_TARGET_ARCH -b -uc"
    if [[ -v PELION_PACKAGE_SKIP_DEPS_CHECKING ]]; then
        PELION_DPKG_BUILD_OPTIONS+=" -d"
    fi

    dpkg-buildpackage $PELION_DPKG_BUILD_OPTIONS

    mv "$PELION_TMP_BUILD_DIR/${PELION_PACKAGE_ARCHIVE_NAME}_${PELION_PACKAGE_TARGET_ARCH}.deb" "$PELION_DEB_DEPLOY_DIR"
}

function pelion_main() {
    pelion_parse_args "$@"

    pelion_env_validate

    pelion_source_preparation
    echo "INFO: Source preparation done!"

    pelion_generation_deb_source_packages
    echo "INFO: Generation debian source packages done!"

    pelion_building_deb_package
    echo "INFO: Building debian package done!"

    echo "INFO: Done!"
}
