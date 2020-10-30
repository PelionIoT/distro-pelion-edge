#!/bin/bash

set -e -u

shopt -s dotglob

PELION_PACKAGE_VERSION_CODENAME=$(cat /etc/os-release \
    | grep VERSION_CODENAME | sed 's/VERSION_CODENAME=//g')
DOCKER_DIST=$PELION_PACKAGE_VERSION_CODENAME

if [ ! -v PELION_PACKAGE_APT_COMPONENT ]; then
    PELION_PACKAGE_APT_COMPONENT=main
fi

BASENAME=$(basename "$0")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR=$(cd "$SCRIPT_DIR"/../.. && pwd)

# import common environment setup
source $SCRIPT_DIR/env-common.sh

function update_pelion_variables
{
    PELION_PACKAGE_VERSION_CODENAME=${PELION_PACKAGE_VERSION_CODENAME:-$DOCKER_DIST}

    if [ -z "$PELION_PACKAGE_VERSION_CODENAME" ]; then
        echo "ERROR: unable to get build codename"
        exit 1
    fi

PELION_DEB_DEPLOY_DIR=$ROOT_DIR/build/deploy/deb/$PELION_PACKAGE_VERSION_CODENAME/$PELION_PACKAGE_APT_COMPONENT
}

PELION_SOURCE_DIR=$ROOT_DIR/build/downloads
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
PELION_METAPACKAGE_GEN=false
PELION_PACKAGE_VERIFY=false

PELION_PACKAGE_DOCKER=false

PELION_PACKAGE_INSTALL_DEPS=false
PELION_PACKAGE_TARGET_ARCH=amd64

PELION_PRINT_TARGET_PACKAGE_NAME=false

if [[ ! -v PELION_PACKAGE_BINARY_NAME ]]; then
	PELION_PACKAGE_BINARY_NAME="${PELION_PACKAGE_NAME}"
fi
PELION_PACKAGE_DEB_BINARY_NAME="$PELION_PACKAGE_BINARY_NAME"_"$PELION_PACKAGE_FULL_VERSION"

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

################################################################################
# Additional helper functions for package building

function pelion_check_no_elf() {
    if find "$1" -type f -exec file {} + | grep -q ELF; then
        echo "Error: $1 have ELF file."
        exit 1
    fi
}

function pelion_update_too_old_files() {
    DEBIAN_POLICY_MIN_YEAR=$(($(date +"%Y")-20))

    find "$1" -print0 |
    while IFS= read -r -d '' File; do
        FILE_MODIFICATION_YEAR=$(date -r "$File" +"%Y")

        if [ "$FILE_MODIFICATION_YEAR" -le "$DEBIAN_POLICY_MIN_YEAR" ]; then
            touch -m $File
        fi
    done
}

################################################################################

function pelion_metapackage_parse_args() {
    PELION_PACKAGE_TARGET_ARCH=all

    for opt in "$@"; do
        case "$opt" in
            --install)
                PELION_PACKAGE_INSTALL_DEPS=true
                ;;

            --verify)
                PELION_PACKAGE_VERIFY=true
                ;;

            --build)
                PELION_METAPACKAGE_GEN=true
                ;;

            --docker=*)
                PELION_PACKAGE_DOCKER=true
                local OPTARG=${opt#*=}
                DOCKER_DIST=${OPTARG:-${DOCKER_DIST}}
                ;;

            --print-target)
                PELION_PRINT_TARGET_PACKAGE_NAME=true
                ;;

            --print-package-name)
                echo $PELION_PACKAGE_NAME
                exit 0
                ;;

            --print-package-version)
                echo $PELION_PACKAGE_FULL_VERSION
                exit 0
                ;;

            --help|-h)
                echo "Usage: $0 [Options]"
                echo ""
                echo "Options:"
                echo " --docker=[dist]     Use docker containers (optional dist eg. bionic, focal...)."
                echo " --build             Build metapackage."
                echo " --verify            Verify metapackage conformity to the Debian policy."
                echo " --install           Install build dependencies."
                echo " --print-target      Print target package file path and exit"
                echo " --print-package-name Print package name (eg. devicejs) and exit"
                echo " --print-package-version Print package version (eg. devicejs) and exit"
                echo " --help,-h           Print this message."
                echo ""
                echo "Default mode: $0 --build --verify"
                exit 0
                ;;
        esac
    done

    update_pelion_variables

    if $PELION_PRINT_TARGET_PACKAGE_NAME; then
        pelion_print_target_package_path
        exit 0
    fi

    if ! $PELION_METAPACKAGE_GEN && ! $PELION_PACKAGE_VERIFY; then
        PELION_METAPACKAGE_GEN=true
        PELION_PACKAGE_VERIFY=true
    fi
}

function pelion_parse_args() {
    for opt in "$@"; do
        case "$opt" in
            --install)
                PELION_PACKAGE_INSTALL_DEPS=true
                ;;

            --arch=*)
                PELION_PACKAGE_TARGET_ARCH="${opt#*=}"
                ;;

            --verify)
                PELION_PACKAGE_VERIFY=true
                ;;

            --build)
                PELION_PACKAGE_BUILD=true
                ;;

            --source)
                PELION_PACKAGE_SOURCE=true
                ;;

            --docker=*)
                PELION_PACKAGE_DOCKER=true
                local OPTARG=${opt#*=}
                DOCKER_DIST=${OPTARG:-bionic}
                ;;

            --print-target)
                PELION_PRINT_TARGET_PACKAGE_NAME=true
                ;;

            --print-package-name)
                echo $PELION_PACKAGE_NAME
                exit 0
                ;;

            --print-package-version)
                echo $PELION_PACKAGE_FULL_VERSION
                exit 0
                ;;

            --help|-h)
                echo "Usage: $0 [Options]"
                echo ""
                echo "Options:"
                echo " --docker            Use docker containers."
                echo " --source            Generate source package."
                echo " --build             Build binary from source generated with --source option."
                echo " --verify            Verify package conformity to the Debian policy."
                echo " --install           Install build dependencies."
                echo " --arch=<arch>       Set target architecture."
                echo " --print-target      Print target package file path and exit"
                echo " --print-package-name Print package name (eg. devicejs) and exit"
                echo " --print-package-version Print package version (eg. devicejs) and exit"
                echo " --help,-h           Print this message."
                echo ""
                echo " If none of '--source', '--build' or '--verify' options are specified,"
                echo " all of them are activated."
                echo ""

                echo "Available architectures:"
                for arch in ${PELION_PACKAGE_SUPPORTED_ARCH[*]}
                do
                    echo "  $arch"
                done
                echo ""

                echo "Default mode: $0 --arch=$PELION_PACKAGE_TARGET_ARCH --source --build --verify"
                exit 0
                ;;
        esac
    done

    update_pelion_variables

    if $PELION_PRINT_TARGET_PACKAGE_NAME; then
        pelion_print_target_package_path
        exit 0
    fi

    if ! $PELION_PACKAGE_SOURCE && ! $PELION_PACKAGE_BUILD && ! $PELION_PACKAGE_VERIFY; then
        PELION_PACKAGE_SOURCE=true
        PELION_PACKAGE_BUILD=true
        PELION_PACKAGE_VERIFY=true
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
        PACKAGE_COMPONENT_SOURCE_DIR=${PELION_SOURCE_DIR}/${PELION_PACKAGE_NAME}/${PACKAGE_COMPONENT_FILENAME}

        if [ ! -d "$PACKAGE_COMPONENT_SOURCE_DIR" ]; then
            git clone $COMPONENT "$PACKAGE_COMPONENT_SOURCE_DIR"
            if [ ! ${PELION_PACKAGE_COMPONENTS[$COMPONENT]} ]; then
                PELION_PACKAGE_COMPONENTS[$COMPONENT]=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
            fi

            cd "$PACKAGE_COMPONENT_SOURCE_DIR"                         && \
            git remote update                                          && \
            git checkout ${PELION_PACKAGE_COMPONENTS[$COMPONENT]}
        fi

    done

    if [ -v PELION_PACKAGE_SOURCE_PREPARATION_CALLBACK ]; then
        $PELION_PACKAGE_SOURCE_PREPARATION_CALLBACK
    fi
}

function pelion_generation_deb_metapackage() {
    rm -rf "$PELION_TMP_BUILD_DIR"

    mkdir -p "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"
    cp -r "$PELION_PACKAGE_DIR/debian" "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"

    if $PELION_PACKAGE_INSTALL_DEPS; then
        sudo apt-get update && \
        sudo apt-get install -y debhelper
    fi

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
        PACKAGE_COMPONENT_SOURCE_DIR=${PELION_SOURCE_DIR}/${PELION_PACKAGE_NAME}/${PACKAGE_COMPONENT_FILENAME}

        if [ ${#PELION_PACKAGE_COMPONENTS[@]} -gt 1 ]; then
            cp -r "$PACKAGE_COMPONENT_SOURCE_DIR" "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/"

            rm -rf "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/$PACKAGE_COMPONENT_FILENAME/.git" \
                   "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/$PACKAGE_COMPONENT_FILENAME/.github"
        else
            cp -r "$PACKAGE_COMPONENT_SOURCE_DIR/." "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/"

            rm -rf "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/.git" \
                   "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/.github"
        fi
    done

    find "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME/" -name .gitignore -exec rm {} +

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

    if [ -v PELION_PACKAGE_PRE_BUILD_CALLBACK ]; then
        $PELION_PACKAGE_PRE_BUILD_CALLBACK
    fi

    if $PELION_PACKAGE_INSTALL_DEPS; then
        sudo apt-get update && \
        sudo apt-get build-dep -y -a "$PELION_PACKAGE_TARGET_ARCH" "$PELION_DEB_DEPLOY_DIR/source/$PELION_PACKAGE_DEB_ARCHIVE_NAME.dsc" -o APT::Immediate-Configure=0
    fi

    tar xf "$PELION_DEB_DEPLOY_DIR/source/$PELION_PACKAGE_ORIG_ARCHIVE_NAME.orig.tar.gz" -C "$PELION_TMP_BUILD_DIR/"
    tar xf "$PELION_DEB_DEPLOY_DIR/source/$PELION_PACKAGE_DEB_ARCHIVE_NAME.debian.tar.xz" -C "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"

    cd "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"

    PELION_DPKG_BUILD_OPTIONS="--host-arch $PELION_PACKAGE_TARGET_ARCH -b -uc"
    if [[ -v PELION_PACKAGE_SKIP_DEPS_CHECKING ]]; then
        PELION_DPKG_BUILD_OPTIONS+=" -d"
    fi

    dpkg-buildpackage $PELION_DPKG_BUILD_OPTIONS

    mv "$PELION_TMP_BUILD_DIR/${PELION_PACKAGE_DEB_BINARY_NAME}_${PELION_PACKAGE_TARGET_ARCH}.deb" "$PELION_DEB_DEPLOY_DIR/binary-$PELION_PACKAGE_TARGET_ARCH"
}

function pelion_verifying_deb_package() {
    if $PELION_PACKAGE_INSTALL_DEPS; then
        sudo apt-get update && \
        sudo apt-get install -y lintian
    fi

    cd $PELION_DEB_DEPLOY_DIR/binary-$PELION_PACKAGE_TARGET_ARCH

    lintian --no-tag-display-limit --info \
        ${PELION_PACKAGE_DEB_BINARY_NAME}_${PELION_PACKAGE_TARGET_ARCH}.deb 2>&1 | tee $PELION_PACKAGE_NAME.lintian
}

function pelion_print_target_package_path()
{
    echo $PELION_DEB_DEPLOY_DIR/binary-$PELION_PACKAGE_TARGET_ARCH/${PELION_PACKAGE_DEB_BINARY_NAME}_${PELION_PACKAGE_TARGET_ARCH}.deb
}
################################################################################
# Docker helpers
################################################################################

function pelion_docker_image_create() {
    IMAGE_NUM=$(docker images | grep -E "^pelion-$DOCKER_DIST-(source|build)\s" | wc -l)
    if [ "$IMAGE_NUM" -ne 2 ]; then
        echo "Creating docker images"
        $ROOT_DIR/build-env/bin/docker-*-$DOCKER_DIST-create.sh
    fi
}

function pelion_docker_build() {
    SCRIPT_PATH=$(cd "`dirname \"$0\"`" && pwd)
    DOCKER_ROOT_DIR="/pelion-build"
    DOCKER_SCRIPT_PATH=$(echo $SCRIPT_PATH | sed "s:^$ROOT_DIR:$DOCKER_ROOT_DIR:")
    APT_REPO="$ROOT_DIR"/build/apt/$DOCKER_DIST
    mkdir -p $APT_REPO

    # Use separate docker containers for source generation and package build.
    if $PELION_PACKAGE_SOURCE; then
        docker run --rm \
            -v "$HOME/.ssh":/home/user/.ssh \
            -v "$ROOT_DIR":"$DOCKER_ROOT_DIR" \
            -v "$APT_REPO":/opt/apt-repo \
            pelion-$DOCKER_DIST-source \
            "$DOCKER_SCRIPT_PATH/$BASENAME" \
                --install --arch=$PELION_PACKAGE_TARGET_ARCH --source
    fi

    if $PELION_PACKAGE_BUILD; then
        docker run --rm \
            -v "$ROOT_DIR":"$DOCKER_ROOT_DIR" \
            -v "$APT_REPO":/opt/apt-repo \
            pelion-$DOCKER_DIST-build \
            "$DOCKER_SCRIPT_PATH/$BASENAME" \
                --install --arch=$PELION_PACKAGE_TARGET_ARCH --build
    fi

    if $PELION_METAPACKAGE_GEN; then
        docker run --rm \
            -v "$ROOT_DIR":"$DOCKER_ROOT_DIR" \
            -v "$APT_REPO":/opt/apt-repo \
            pelion-$DOCKER_DIST-build \
            "$DOCKER_SCRIPT_PATH/$BASENAME" \
                --install --build
    fi

    if $PELION_PACKAGE_VERIFY; then
        docker run --rm \
            -v "$HOME/.ssh":/home/user/.ssh \
            -v "$ROOT_DIR":"$DOCKER_ROOT_DIR" \
            -v "$APT_REPO":/opt/apt-repo \
            pelion-$DOCKER_DIST-source \
            "$DOCKER_SCRIPT_PATH/$BASENAME" \
               --arch=$PELION_PACKAGE_TARGET_ARCH --verify
    fi
}
################################################################################

function pelion_metapackage_main() {
    pelion_metapackage_parse_args "$@"

    if $PELION_PACKAGE_DOCKER; then
        pelion_docker_image_create
        pelion_docker_build
        exit 0
    fi

    if $PELION_METAPACKAGE_GEN; then
        echo "INFO: Building Debian metapackage!"
        pelion_generation_deb_metapackage
    fi

    if $PELION_PACKAGE_VERIFY; then
        echo "INFO: Verifying Debian metapackage!"
        pelion_verifying_deb_package
    fi

    echo "INFO: Done!"
}

function pelion_main() {
    pelion_parse_args "$@"

    pelion_env_validate

    if $PELION_PACKAGE_DOCKER; then
        pelion_docker_image_create
        pelion_docker_build
        exit 0
    fi

    if $PELION_PACKAGE_SOURCE; then
        echo "INFO: Source preparation!"
        pelion_source_preparation

        echo "INFO: Generating Debian source packages!"
        pelion_generation_deb_source_packages
    fi

    if $PELION_PACKAGE_BUILD; then
        echo "INFO: Building Debian package!"
        pelion_building_deb_package
    fi

    if $PELION_PACKAGE_VERIFY; then
        echo "INFO: Verifying Debian package!"
        pelion_verifying_deb_package
    fi

    echo "INFO: Done!"
}
