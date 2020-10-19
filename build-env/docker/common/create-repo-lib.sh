#!/bin/bash

APT_REPO_PATH=/opt/apt-repo

# function to create "Packages.gz" for custom repo
function apt_scan_packages
(
    local APT_REPO_NAME=$1
    cd $APT_REPO_PATH
    dpkg-scanpackages $APT_REPO_NAME | sudo bash -c "gzip >$APT_REPO_NAME/Packages.gz"
)

# create custom repo and add it as trusted
function apt_create_trusted_repo
{
    local APT_REPO_NAME=$1
    sudo mkdir -p $APT_REPO_PATH/$APT_REPO_NAME
    sudo bash -c "echo \"deb [trusted=yes] file://$APT_REPO_PATH $APT_REPO_NAME/\" >/etc/apt/sources.list.d/$APT_REPO_NAME.list"
}

# put package to custom repo
function apt_put_package_to_repo
{
    local APT_PACKAGE=$1
    local APT_REPO_NAME=$2

    sudo cp $APT_PACKAGE $APT_REPO_PATH/$APT_REPO_NAME/
}

# pin package
# example:  apt_pin_package golang-virtual 14-1
function apt_pin_package
{
    local APT_PACKAGE=$1
    local APT_PACKAGE_VERSION=$2

sudo bash -c "cat >\"/etc/apt/preferences.d/90-$APT_PACKAGE\" <<EOF
Package: $APT_PACKAGE
Pin: version $APT_PACKAGE_VERSION
Pin-Priority: 900
EOF
"
}

# Example:
# apt_create_trusted_repo pe-languages
# apt_put_package_to_repo /pelion-build/deploy/myfile.deb pe-languages
# apt_scan_packages

# runs $BUILD_SCRIPT (2st arg), creates $TARGET_REPO_NAME (1nd arg) debian repository
# and adds created package there. Pins that package. Pass remainig args to build script
# example: build_and_put_to_repo pe-languages pe-nodejs/deb/build.sh --install
function build_and_put_to_repo
{
    set -e
    TARGET_REPO_NAME=$1
    BUILD_SCRIPT=$2
    local DEB_PKG=$($BUILD_SCRIPT --print-target)
    local TARGET_PACKAGE_NAME=$($BUILD_SCRIPT --print-package-name)
    local TARGET_PACKAGE_VERSION=$($BUILD_SCRIPT --print-package-version)

    echo "Preparing $TARGET_PACKAGE_NAME $TARGET_PACKAGE_VERSION in $TARGET_REPO_NAME from $DEB_PKG"

    shift 2
    $BUILD_SCRIPT $@

    apt_create_trusted_repo $TARGET_REPO_NAME
    apt_put_package_to_repo $DEB_PKG $TARGET_REPO_NAME
    apt_scan_packages $TARGET_REPO_NAME
    apt_pin_package $TARGET_PACKAGE_NAME $TARGET_PACKAGE_VERSION
}
