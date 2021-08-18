#!/bin/bash

set -e

shopt -s dotglob

export GPG_TTY=$(tty)

SCRIPT_DIR=$(cd "`dirname \"$0\"`" && pwd)
ROOT_DIR=$(cd "`dirname \"$0\"`"/../.. && pwd)

PELION_DEB_DEPLOY_DIR=$ROOT_DIR/build/deploy/deb
PELION_DEB_TMP_BUILD_DIR=$ROOT_DIR/build/tmp-build
PELION_APT_REPO_DIR=$PELION_DEB_DEPLOY_DIR/apt-repo

PELION_GPG_KEYNAME=Pelion_GPG_key_private.gpg
PELION_GPG_KEY_ID=""
PELION_GPG_KEY_PATH=$PELION_DEB_DEPLOY_DIR/gpg
PELION_GPG_ENABLE_SIGNING=true

PELION_APT_REPO_INSTALL=false

PELION_APT_REPO_GPG_KEY_FILE=key.gpg
PELION_APT_REPO_GPG_KEY_PATH=$PELION_APT_REPO_DIR

PELION_PACKAGES_SUPPORTED_DIST_DEFAULT=(bionic stretch)
PELION_PACKAGES_SUPPORTED_COMPONENTS=(main)
PELION_PACKAGES_SUPPORTED_ARCH=(amd64 arm64 armhf armel all)

PELION_PACKAGES_SUPPORTED_DIST=()

function pelion_apt_repo_parse_args() {
    for opt in "$@"; do
        case "$opt" in
            --key-name=*)
                PELION_GPG_KEYNAME="${opt#*=}"
                ;;

            --key-id=*)
                PELION_GPG_KEY_ID="${opt#*=}"
                ;;

            --key-path=*)
                PELION_GPG_KEY_PATH="${opt#*=}"
                ;;

            --install)
                PELION_APT_REPO_INSTALL=true
                ;;

            --no-sign)
                PELION_GPG_ENABLE_SIGNING=false
                ;;

            --help|-h)
                echo "Usage: $(basename "$0") [Options] [input-distro[=output-name] [...]]"
                echo ""
                echo "Options:"
                echo " --key-name=<name>         Filename of secret GPG key."
                echo " --key-[id|path]=<id|path> Use key id of existing GPG key or path where private key is placed."
                echo " --install                 Installs the necessary tools to create structure for apt repository."
                echo " --no-sign                 Don't sign any files with GPG"
                echo " --help,-h                 Print this message."
                echo ""
                echo "Default mode: $(basename "$0") --key-name=$PELION_GPG_KEYNAME --key-path=$PELION_GPG_KEY_PATH"
                echo ""
                echo "Example: $(basename "$0") --key-path=/home/vagrant/.ssh --key-name=my_apt_repo.key buster=buster-next focal"
                exit 0
                ;;

            -*)
                echo "Unknown option: ${opt}. Try --help."
                exit 1
                ;;

            *)
                PELION_PACKAGES_SUPPORTED_DIST+=(${opt})
                ;;
        esac
    done
    if [ ${#PELION_PACKAGES_SUPPORTED_DIST[@]} = 0 ]; then
        PELION_PACKAGES_SUPPORTED_DIST=(${PELION_PACKAGES_SUPPORTED_DIST_DEFAULT[@]})
    fi
}

function pelion_apt_repo_gpg_import() {
    if [ -n "$PELION_GPG_KEY_ID" ]; then
        echo "INFO: Using key id of existing gpg key."

        gpg --list-keys $PELION_GPG_KEY_ID > /dev/null 2>&1 \
            || { echo "ERROR: GPG key with '$PELION_GPG_KEY_ID' key id not found!"; exit 1; }
    else
        echo "INFO: Using gpg key from path."

        if [ ! -f "$PELION_GPG_KEY_PATH/$PELION_GPG_KEYNAME" ]; then
            echo "ERROR: $PELION_GPG_KEY_PATH/$PELION_GPG_KEYNAME key not found."
            exit 1
        fi

        PELION_GPG_KEY_ID=$(gpg --import "$PELION_GPG_KEY_PATH/$PELION_GPG_KEYNAME" 2>&1 \
            | grep -P 'gpg: key [0-9A-F]{8,32}' | head -n 1 | grep -P -o '[0-9A-F]{8,32}' || echo "" )

        if [ -z $PELION_GPG_KEY_ID ]; then
            echo "ERROR: Can not import $PELION_GPG_KEY_PATH/$PELION_GPG_KEYNAME gpg key!"
            exit 1
        fi
    fi

    mkdir -p "$PELION_APT_REPO_GPG_KEY_PATH"
    gpg --yes --armor --output "$PELION_APT_REPO_GPG_KEY_PATH/$PELION_APT_REPO_GPG_KEY_FILE" --export $PELION_GPG_KEY_ID
}

function pelion_apt_repo_pool_update() {
    PELION_APT_REPO_POOL_COMPONENTS=$(echo ${PELION_PACKAGES_SUPPORTED_COMPONENTS[@]} | sed -e 's/ /|/g')
    PELION_APT_REPO_POOL_ARCHS=$(echo ${PELION_PACKAGES_SUPPORTED_ARCH[@]} | sed -e 's/ /|/g')

    mkdir -p "$PELION_APT_REPO_DIR/pool"

    cd "$PELION_DEB_DEPLOY_DIR"

    for PELION_APT_REPO_POOL_DIST in ${PELION_PACKAGES_SUPPORTED_DIST[@]}; do

        pushd "${PELION_APT_REPO_POOL_DIST%=*}" || continue

        mkdir -p "$PELION_APT_REPO_DIR/pool/${PELION_APT_REPO_POOL_DIST#*=}"

        find . -mindepth 3 -maxdepth 3 -regextype posix-extended -regex \
            "\./($PELION_APT_REPO_POOL_COMPONENTS)/source/.*(orig\.tar\.gz|debian\.tar\.xz|\.tar\.gz|dsc)" \
            -exec cp --parents -t "$PELION_APT_REPO_DIR/pool/${PELION_APT_REPO_POOL_DIST#*=}" {} +

        find . -mindepth 3 -maxdepth 3 -regextype posix-extended -regex \
            "\./($PELION_APT_REPO_POOL_COMPONENTS)/binary-($PELION_APT_REPO_POOL_ARCHS)/.*\2\.deb" \
            -exec cp --parents -t "$PELION_APT_REPO_DIR/pool/${PELION_APT_REPO_POOL_DIST#*=}" {} +

        popd

    done
}

function pelion_apt_repo_pool_sign_with_gpg_key() {
    cd "$PELION_APT_REPO_DIR"

    find pool -name '*.dsc' \
        -exec debsign -k $PELION_GPG_KEY_ID {} +

    find pool -name '*.deb' \
        -exec dpkg-sig -k $PELION_GPG_KEY_ID --sign repo {} +
}

function pelion_apt_repo_dists_component_create() {
    DISTRIBUTION_DIR_NAME=$1
    COMPONENT_DIR_NAME=$2
    ARCH_DIR_NAME=$3

    if [ $ARCH_DIR_NAME ==  source ]; then
        PACKAGE_TYPE=Sources
        PACKAGE_ARCH=source
    else
        PACKAGE_TYPE=Packages
        PACKAGE_ARCH=$(echo $ARCH_DIR_NAME | sed 's/binary-//')
    fi

    POOL_COMPONENT_DIR_PREFIX="$PELION_APT_REPO_DIR/pool/$DISTRIBUTION_DIR_NAME/$COMPONENT_DIR_NAME"
    DISTS_ARCH_DIR_PREFIX="$PELION_APT_REPO_DIR/dists/$DISTRIBUTION_DIR_NAME/$COMPONENT_DIR_NAME/$ARCH_DIR_NAME"

    mkdir -p "$PELION_DEB_TMP_BUILD_DIR"

    apt-ftparchive --md5=no --sha1=no --sha256=no --sha512=no -o APT::FTPArchive::Release::Origin="ARM" \
        -o APT::FTPArchive::Release::Label="Pelion" \
        -o APT::FTPArchive::Release::Version="0.0.1" \
        -o APT::FTPArchive::Release::Codename="$DISTRIBUTION_DIR_NAME" \
        -o APT::FTPArchive::Release::Components="$COMPONENT_DIR_NAME" \
        -o APT::FTPArchive::Release::Architectures="$PACKAGE_ARCH" \
        release "$POOL_COMPONENT_DIR_PREFIX/" > "$PELION_DEB_TMP_BUILD_DIR/Release"

    mv "$PELION_DEB_TMP_BUILD_DIR/Release" "$DISTS_ARCH_DIR_PREFIX/Release"

    cd "$PELION_APT_REPO_DIR"

    FTPARCHIVE_OPERATION_TYPE=$(echo "$PACKAGE_TYPE" | awk '{print tolower($0)}')
    apt-ftparchive $FTPARCHIVE_OPERATION_TYPE "pool/$DISTRIBUTION_DIR_NAME/$COMPONENT_DIR_NAME/$ARCH_DIR_NAME" > "$DISTS_ARCH_DIR_PREFIX/$PACKAGE_TYPE"

    gzip -9 -c "$DISTS_ARCH_DIR_PREFIX/$PACKAGE_TYPE" >  "$DISTS_ARCH_DIR_PREFIX/$PACKAGE_TYPE.gz"
    xz -c "$DISTS_ARCH_DIR_PREFIX/$PACKAGE_TYPE" > "$DISTS_ARCH_DIR_PREFIX/$PACKAGE_TYPE.xz"

    unset PACKAGE_ARCH
    unset PACKAGE_TYPE

    unset ARCH_DIR_NAME
    unset COMPONENT_DIR_NAME
    unset DISTRIBUTION_DIR_NAME
}

function pelion_apt_repo_dists_distribution_create() {
    DISTRIBUTION_DIR_NAME=$1

    cd "$PELION_APT_REPO_DIR/dists/$DISTRIBUTION_DIR_NAME"

    for component_path in $(find . -mindepth 1 -maxdepth 1 -type d); do
        DISTRIBUTION_SUPPORTED_COMPONENTS+=( $(basename "$component_path"))
    done

    for arch_path in $(find . -mindepth 2 -maxdepth 2 -type d); do
        if [[ "$(basename "$arch_path")" == "binary-"* ]]; then
            DISTRIBUTION_SUPPORTED_ARCH+=( $(echo $(basename "$arch_path") | sed 's/binary-//'))
        fi
    done

    DISTRIBUTION_SUPPORTED_ARCH=( `for i in ${DISTRIBUTION_SUPPORTED_ARCH[@]}; do echo $i; done | sort -u` )

    mkdir -p "$PELION_DEB_TMP_BUILD_DIR"

    apt-ftparchive -o APT::FTPArchive::Release::Origin="ARM" \
        -o APT::FTPArchive::Release::Label="Pelion" \
        -o APT::FTPArchive::Release::Version="0.0.1" \
        -o APT::FTPArchive::Release::Codename="$DISTRIBUTION_DIR_NAME" \
        -o APT::FTPArchive::Release::Components="${DISTRIBUTION_SUPPORTED_COMPONENTS[*]}" \
        -o APT::FTPArchive::Release::Architectures="${DISTRIBUTION_SUPPORTED_ARCH[*]}" \
    release . > "$PELION_DEB_TMP_BUILD_DIR/Release"

    mv "$PELION_DEB_TMP_BUILD_DIR/Release" .

    for arch in "${DISTRIBUTION_SUPPORTED_ARCH[@]}"; do
        apt-ftparchive --arch=$arch contents "$PELION_APT_REPO_DIR/pool/$DISTRIBUTION_DIR_NAME" | gzip -9 -c > "Contents-$arch.gz"
    done

    unset DISTRIBUTION_SUPPORTED_ARCH
    unset DISTRIBUTION_SUPPORTED_COMPONENTS
    unset DISTRIBUTION_DIR_NAME
}

function pelion_apt_repo_dists_update() {
    if [ -d "$PELION_APT_REPO_DIR/dists" ]; then rm -rf "$PELION_APT_REPO_DIR/dists"; fi

    mkdir -p "$PELION_APT_REPO_DIR/dists"

    # Loop throught distribution subdirectories of apt-repo/pool
    for dist_subdirectory in "$PELION_APT_REPO_DIR/pool/"*/ ; do
        current_dist=$(basename "$dist_subdirectory")

        # Loop throught component subdirectories of apt-repo/pool/distribution
        for component_subdirectory in "$dist_subdirectory"*/ ; do
            current_component=$(basename "$component_subdirectory")

            # Loop throught binary-arch and source subdirectories of apt-repo/pool/distribution/component
            for source_or_binary_subdirectory in "$component_subdirectory"*/ ; do
                current_source_or_binary=$(basename "$source_or_binary_subdirectory")

                mkdir -p "$PELION_APT_REPO_DIR/dists/$current_dist/$current_component/$current_source_or_binary"

                if [[ "$current_source_or_binary" ==  "source" ]] || [[ "$current_source_or_binary" == "binary-"* ]]; then
                    pelion_apt_repo_dists_component_create $current_dist $current_component $current_source_or_binary
                else
                    echo "Warning: Unknown directory $current_source_or_binary (Neither 'source' nor 'binary-arch')!"
                fi

            done
        done

        pelion_apt_repo_dists_distribution_create $current_dist

    done
}

function pelion_apt_repo_dists_sign_with_gpg_key() {
    for dist_subdirectory in "$PELION_APT_REPO_DIR/dists/"*/; do
        gpg --default-key $PELION_GPG_KEY_ID --digest-algo SHA512 -abs -o "$dist_subdirectory/Release.gpg" "$dist_subdirectory/Release"
        gpg --default-key $PELION_GPG_KEY_ID --digest-algo SHA512 -a -s --clearsign -o "$dist_subdirectory/InRelease" "$dist_subdirectory/Release"
    done
}

function pelion_apt_repo_update() {
    pelion_apt_repo_parse_args "$@"

    if $PELION_APT_REPO_INSTALL; then
        sudo apt-get update && \
        sudo apt-get install -y gnupg devscripts dpkg-sig apt-utils
    fi

    if $PELION_GPG_ENABLE_SIGNING; then
        pelion_apt_repo_gpg_import
    fi

    pelion_apt_repo_pool_update
    if $PELION_GPG_ENABLE_SIGNING; then
        pelion_apt_repo_pool_sign_with_gpg_key
    fi

    pelion_apt_repo_dists_update
    if $PELION_GPG_ENABLE_SIGNING; then
        pelion_apt_repo_dists_sign_with_gpg_key
    fi
}

# Entry point
pelion_apt_repo_update "$@"
