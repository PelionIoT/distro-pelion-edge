#!/bin/bash

nodejs_arch() {
    case "$1" in
        x86_64) echo x64  ;;
        i686)   echo x86  ;;
        aarch64) echo arm64 ;;
        *)      echo "$1" ;;
    esac
}

override_download() {
    nodejs_ver="$(spec_ver "$specdir/$specfile")"
    nodejs_arch="$(nodejs_arch "$(uname -m)")"
    nodejs_dir="node-v$nodejs_ver-linux-$nodejs_arch"
    nodejs_tar="$nodejs_dir.tar.xz"

    cd "$cachedir"
    if [ ! -f "$nodejs_tar" ]; then
        curl -OL "https://nodejs.org/dist/v$nodejs_ver/$nodejs_tar"
    fi
}

override_conjure_sources() {
    cd "$builddir"
    rm -rf node_root
    mkdir node_root
    tar -Jxf "$cachedir/$nodejs_tar" --strip-components=1 -C node_root
}

. "${0%/*}"/../../build-env/inc/rpm-common.sh
