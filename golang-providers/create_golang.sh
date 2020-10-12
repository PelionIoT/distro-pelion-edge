#!/bin/bash
SCRIPT_DIR=$(realpath $(dirname ${BASH_SOURCE[0]}))

source $SCRIPT_DIR/../build-env/inc/create_repo_lib.sh

# 1. decide: if we can install golang-1.14-go or we need to create binary package
# 2. create package providing: pe-golang
# 3. create repository pe-languages, put package in there, apt update

GOLANG_REPO=pe-languages

function build_golang_virtual
{
    $SCRIPT_DIR/golang-virtual/deb/build.sh
    DEB_PKG=$($SCRIPT_DIR/golang-virtual/deb/build.sh --print-target)
    apt_create_trusted_repo $GOLANG_REPO
    apt_put_package_to_repo $DEB_PKG $GOLANG_REPO
    apt_pin_package golang-virtual 14-1
}

build_golang_virtual
