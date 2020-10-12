#!/bin/bash

APT_REPO_PATH=/opt/apt-repo

# function to create "Packages.gz" for custom repo
function apt_scan_packages
(
    local APT_REPO_NAME=$1
    cd $APT_REPO_PATH
    dpkg-scanpackages $APT_REPO_NAME | gzip >$APT_REPO_NAME/Packages.gz
)

# create custom repo and add it as trusted
function apt_create_trusted_repo
{
    local APT_REPO_NAME=$1
    mkdir -p $APT_REPO_PATH/$APT_REPO_NAME
    echo "deb [trusted=yes] file://$APT_REPO_PATH $APT_REPO_NAME/" >/etc/apt/sources.list.d/$APT_REPO_NAME.list
}

# put package to custom repo
function apt_put_package_to_repo
{
    local APT_PACKAGE=$1
    local APT_REPO_NAME=$2

    cp $APT_PACKAGE $APT_REPO_PATH/$APT_REPO_NAME/
}

# pin package
# example:  apt_pin_package golang-virtual 14-1
function apt_pin_package
{
    local APT_PACKAGE=$1
    local APT_PACKAGE_VERSION=$2

cat > "/etc/apt/preferences.d/90-$APT_PACKAGE" <<EOF
Package: $APT_PACKAGE
Pin: version $APT_PACKAGE_VERSION
Pin-Priority: 900
EOF
}

# Example:
# apt_create_trusted_repo pe-languages
# apt_put_package_to_repo /pelion-build/deploy/myfile.deb pe-languages
# apt_scan_packages
