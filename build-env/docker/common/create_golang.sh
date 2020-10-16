#!/bin/bash
SCRIPT_DIR=$(realpath $(dirname ${BASH_SOURCE[0]}))
ROOT_DIR=$SCRIPT_DIR/../../..

source $SCRIPT_DIR/create-repo-lib.sh

TARGET_REPO_NAME=pe-languages
BUILD_SCRIPT=$ROOT_DIR/golang-providers/golang-virtual/deb/build.sh

build_and_put_to_repo $TARGET_REPO_NAME $BUILD_SCRIPT $@
