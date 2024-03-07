#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="golang-virtual"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

GOLANG_VERSION=1.18

source "$PELION_PACKAGE_DIR"/../../../build-env/inc/build-common.sh

PELION_PACKAGE_PRE_BUILD_DEP_CALLBACK=cache_golang_packages

function cache_golang_packages() {
    echo "Caching golang-$GOLANG_VERSION in local repository"
    local OUTPUT_DIR="$ROOT_DIR"/build/repo/$DOCKER_DIST/pe-dependencies/

    mkdir -p $OUTPUT_DIR
    cd $OUTPUT_DIR

    for((i=0; i<5; i++)); do
	    if apt-get -y download golang-$GOLANG_VERSION golang-${GOLANG_VERSION}-go golang-${GOLANG_VERSION}-src; then
            break;
        else
            if [ $i == 4 ]; then
                echo "Unable to get golang from external repository"
                false
            fi

            echo "Retrying..."
        fi
    done
    cd -
}

pelion_metapackage_main "$@"
