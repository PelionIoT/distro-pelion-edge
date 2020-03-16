#!/bin/bash

set -e -u

shopt -s dotglob

PELION_PACKAGE_VERSION_CODENAME=$(cat /etc/os-release \
    | grep VERSION_CODENAME | sed 's/VERSION_CODENAME=//g')

if [ ! -v PELION_PACKAGE_APT_COMPONENT ]; then
    PELION_PACKAGE_APT_COMPONENT=main
fi

BASENAME=$(basename "$0")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR=$(cd "$SCRIPT_DIR"/../.. && pwd)

PELION_SOURCE_DIR=$ROOT_DIR/build/downloads
PELION_DEB_DEPLOY_DIR=$ROOT_DIR/build/deploy/deb/$PELION_PACKAGE_VERSION_CODENAME/$PELION_PACKAGE_APT_COMPONENT
PELION_TMP_BUILD_DIR=$ROOT_DIR/build/tmp-build/$PELION_PACKAGE_NAME

PELION_PACKAGE_FULL_VERSION=$(cd "$PELION_PACKAGE_DIR"; dpkg-parsechangelog --show-field Version)
PELION_PACKAGE_VERSION=$(echo $PELION_PACKAGE_FULL_VERSION \
    | sed -r 's/([0-9]+\.[0-9]+(\.[0-9]+)?).*/\1/') # Version without Revision

PELION_PACKAGE_FOLDER_NAME="$PELION_PACKAGE_NAME"-"$PELION_PACKAGE_VERSION"
PELION_PACKAGE_ORIG_ARCHIVE_NAME="$PELION_PACKAGE_NAME"_"$PELION_PACKAGE_VERSION"
PELION_PACKAGE_DEB_ARCHIVE_NAME="$PELION_PACKAGE_NAME"_"$PELION_PACKAGE_FULL_VERSION"

# Default value of build options
PELION_PACKAGE_SOURCE=false
PELION_PACKAGE_BUILD=false
PELION_PACKAGE_DOCKER=false

PELION_PACKAGE_INSTALL_DEPS=false
PELION_PACKAGE_TARGET_ARCH=amd64

if [[ ! -v PELION_PACKAGE_SUPPORTED_ARCH ]]; then
    PELION_PACKAGE_SUPPORTED_ARCH=(amd64 arm64 armhf armel)
fi

################################################################################
# Terminate script by explicit signal handler to stop docker container.
trap 'sig_handle' INT

function sig_handle() {
    exit 130
}
################################################################################

function pelion_parse_args() {
    for opt in "$@"; do
        case "$opt" in
            --install)
                PELION_PACKAGE_INSTALL_DEPS=true
                ;;

            --arch=*)
                PELION_PACKAGE_TARGET_ARCH="${opt#*=}"
                ;;

            --build)
                PELION_PACKAGE_BUILD=true
                ;;

            --source)
                PELION_PACKAGE_SOURCE=true
                ;;

            --docker)
                PELION_PACKAGE_DOCKER=true
                ;;

            --help|-h)
                echo "Usage: $0 [Options]"
                echo ""
                echo "Options:"
                echo " --docker            Use docker containers."
                echo " --source            Generate source package."
                echo " --build             Build binary from source generated with --source option."
                echo " --install           Install build dependencies."
                echo " --arch=<arch>       Set target architecture."
                echo " --help,-h           Print this message."
                echo ""
                echo "If neither '--source' nor '--build' option is specified both are activated."
                echo ""

                echo "Available architectures:"
                for arch in ${PELION_PACKAGE_SUPPORTED_ARCH[*]}
                do
                    echo "  $arch"
                done
                echo ""

                echo "Default mode: $0 --arch=$PELION_PACKAGE_TARGET_ARCH"
                exit 0
                ;;
        esac
    done

    if ! $PELION_PACKAGE_SOURCE && ! $PELION_PACKAGE_BUILD; then
        PELION_PACKAGE_SOURCE=true
        PELION_PACKAGE_BUILD=true
    fi
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

function pelion_generation_deb_metapackage() {
    rm -rf "$PELION_TMP_BUILD_DIR"

    mkdir -p "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"
    cp -r "$PELION_PACKAGE_DIR/debian" "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"

    cd "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME" && \
        dpkg-buildpackage -us -uc

    mkdir -p "$PELION_DEB_DEPLOY_DIR/source"
    mkdir -p "$PELION_DEB_DEPLOY_DIR/binary-all"

    mv "$PELION_TMP_BUILD_DIR/"{*.tar.gz,*.dsc} "$PELION_DEB_DEPLOY_DIR/source"
    mv "$PELION_TMP_BUILD_DIR/"*.deb            "$PELION_DEB_DEPLOY_DIR/binary-all"
}

function pelion_generation_deb_source_packages() {
    mkdir -p "$PELION_DEB_DEPLOY_DIR/source"

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

    tar czf "$PELION_DEB_DEPLOY_DIR/source/$PELION_PACKAGE_ORIG_ARCHIVE_NAME.orig.tar.gz" -C "$PELION_TMP_BUILD_DIR" "$PELION_PACKAGE_FOLDER_NAME"
    cp -r "$PELION_PACKAGE_DIR/debian" "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"

    cd "$PELION_DEB_DEPLOY_DIR/source" && \
    dpkg-source -b "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"
}

function pelion_building_deb_package() {
    mkdir -p "$PELION_DEB_DEPLOY_DIR/binary-$PELION_PACKAGE_TARGET_ARCH"

    rm -rf "$PELION_TMP_BUILD_DIR"
    mkdir -p "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"

    if $PELION_PACKAGE_INSTALL_DEPS; then
        sudo apt-get update && \
        sudo apt-get build-dep -y -a "$PELION_PACKAGE_TARGET_ARCH" "$PELION_DEB_DEPLOY_DIR/source/$PELION_PACKAGE_DEB_ARCHIVE_NAME.dsc"
    fi

    tar xf "$PELION_DEB_DEPLOY_DIR/source/$PELION_PACKAGE_ORIG_ARCHIVE_NAME.orig.tar.gz" -C "$PELION_TMP_BUILD_DIR/"
    tar xf "$PELION_DEB_DEPLOY_DIR/source/$PELION_PACKAGE_DEB_ARCHIVE_NAME.debian.tar.xz" -C "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"

    cd "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"

    PELION_DPKG_BUILD_OPTIONS="--host-arch $PELION_PACKAGE_TARGET_ARCH -b -uc"
    if [[ -v PELION_PACKAGE_SKIP_DEPS_CHECKING ]]; then
        PELION_DPKG_BUILD_OPTIONS+=" -d"
    fi

    dpkg-buildpackage $PELION_DPKG_BUILD_OPTIONS

    mv "$PELION_TMP_BUILD_DIR/${PELION_PACKAGE_DEB_ARCHIVE_NAME}_${PELION_PACKAGE_TARGET_ARCH}.deb" "$PELION_DEB_DEPLOY_DIR/binary-$PELION_PACKAGE_TARGET_ARCH"
}

################################################################################
# Docker helpers
################################################################################

DOCKER_DIST="bionic"

function pelion_docker_image_create() {
    IMAGE_NUM=$(docker images | grep -E "^pelion-$DOCKER_DIST-(source|build)\s" | wc -l)
    if [ "$IMAGE_NUM" -ne 2 ]; then
        echo "Creating docker images"
        "$ROOT_DIR/build-env/bin/docker-ubuntu-$DOCKER_DIST-create.sh"
    fi
}

function pelion_docker_build() {
    SCRIPT_PATH=$(cd "`dirname \"$0\"`" && pwd)
    DOCKER_ROOT_DIR="/pelion-build"
    DOCKER_SCRIPT_PATH=$(echo $SCRIPT_PATH | sed "s:^$ROOT_DIR:$DOCKER_ROOT_DIR:")

    # Use separate docker containers for source generation and package build.
    if $PELION_PACKAGE_SOURCE; then
        docker run \
            -v "$HOME/.ssh":/home/user/.ssh \
            -v "$ROOT_DIR":"$DOCKER_ROOT_DIR" \
            pelion-$DOCKER_DIST-source \
            "$DOCKER_SCRIPT_PATH/$BASENAME" \
                --install --arch=$PELION_PACKAGE_TARGET_ARCH --source
    fi

    if $PELION_PACKAGE_BUILD; then
        docker run \
            -v "$ROOT_DIR":"$DOCKER_ROOT_DIR" \
            pelion-$DOCKER_DIST-build \
            "$DOCKER_SCRIPT_PATH/$BASENAME" \
                --install --arch=$PELION_PACKAGE_TARGET_ARCH --build
    fi
}
################################################################################

function pelion_main() {
    pelion_parse_args "$@"

    pelion_env_validate

    if $PELION_PACKAGE_DOCKER; then
        pelion_docker_image_create
        pelion_docker_build
        exit 0
    fi

    if $PELION_PACKAGE_SOURCE; then
        pelion_source_preparation
        echo "INFO: Source preparation done!"

        pelion_generation_deb_source_packages
        echo "INFO: Generation Debian source packages done!"
    fi

    if $PELION_PACKAGE_BUILD; then
        pelion_building_deb_package
        echo "INFO: Building Debian package done!"
    fi

    echo "INFO: Done!"
}
