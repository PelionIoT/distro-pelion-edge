#!/bin/bash

PELION_PACKAGE_NAME="pe-nodejs"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh


NODEJS_DOWNLOAD_DIR="$PELION_SOURCE_DIR/nodejs.org"

# Node version is based on the package version in 'debian/changelog'
NODE_VERSION=$PELION_PACKAGE_VERSION

declare -A NODE_ARCH_MAP=( \
    ["amd64"]="x64"   \
    ["arm64"]="arm64" \
    ["armhf"]="armv7l" \
)

NODE_URL_PREFIX="https://nodejs.org/dist/v$NODE_VERSION"
NODE_URL_SHA_FILENAME="SHASUMS256.txt"

function pe_nodejs_sha_verify() {
    echo "Verifying '$NODE_URL_BINARY_FILENAME'"
    grep $NODE_URL_BINARY_FILENAME SHASUMS256.txt | sha256sum --check --strict --status
}

function pe_nodejs_deb_package_source_prepare() {
    mkdir -p "$NODEJS_DOWNLOAD_DIR"
    cd  "$NODEJS_DOWNLOAD_DIR"

    # Download SHA256 file
    if ! wget -q -O $NODE_URL_SHA_FILENAME "$NODE_URL_PREFIX/$NODE_URL_SHA_FILENAME"; then
        echo "Error: Failed to download $NODE_URL_PREFIX/$NODE_URL_SHA_FILENAME"
        exit 1
    fi

    if ! pe_nodejs_sha_verify ; then
        echo "Downloading $NODE_URL_PREFIX/$NODE_URL_BINARY_FILENAME"
        wget -O $NODE_URL_BINARY_FILENAME "$NODE_URL_PREFIX/$NODE_URL_BINARY_FILENAME"
        if ! pe_nodejs_sha_verify; then
            echo "Error: Failed to verify downloaded binary"
            exit 1
        fi
    fi
}

function pe_nodejs_deb_package_build() {
    if $PELION_PACKAGE_INSTALL_DEPS; then
        sudo apt-get update
        sudo apt-get install -y \
            debhelper \
            libc6:$PELION_PACKAGE_TARGET_ARCH \
            libstdc++6:$PELION_PACKAGE_TARGET_ARCH
    fi

    mkdir -p "$PELION_DEB_DEPLOY_DIR/binary-$PELION_PACKAGE_TARGET_ARCH"

    rm -rf "$PELION_TMP_BUILD_DIR"
    mkdir -p "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"

    tar xf "$NODEJS_DOWNLOAD_DIR/$NODE_URL_BINARY_FILENAME" --strip-components=1 \
        -C "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"
    cp -r "$PELION_PACKAGE_DIR/debian" "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"
    
    cd "$PELION_TMP_BUILD_DIR/$PELION_PACKAGE_FOLDER_NAME"

    dpkg-buildpackage --host-arch "$PELION_PACKAGE_TARGET_ARCH" -b -uc

    mv "$PELION_TMP_BUILD_DIR/${PELION_PACKAGE_DEB_ARCHIVE_NAME}_${PELION_PACKAGE_TARGET_ARCH}.deb" \
        "$PELION_DEB_DEPLOY_DIR/binary-$PELION_PACKAGE_TARGET_ARCH"
}

function pe_nodejs_main() {
    pelion_parse_args "$@"

    pelion_env_validate

    if $PELION_PACKAGE_DOCKER; then
        pelion_docker_image_create
        pelion_docker_build
        exit 0
    fi

    NODE_URL_BINARY_FILENAME="node-v$NODE_VERSION-linux-${NODE_ARCH_MAP["$PELION_PACKAGE_TARGET_ARCH"]}.tar.xz"

    if $PELION_PACKAGE_SOURCE; then
        echo "INFO: Source preparation!"
        pe_nodejs_deb_package_source_prepare
    fi

    if $PELION_PACKAGE_BUILD; then
        echo "INFO: Building Debian package!"
        pe_nodejs_deb_package_build
    fi

    if $PELION_PACKAGE_VERIFY; then
        echo "INFO: Verifying Debian package!"
        pelion_verifying_deb_package
    fi
}

pe_nodejs_main "$@"
