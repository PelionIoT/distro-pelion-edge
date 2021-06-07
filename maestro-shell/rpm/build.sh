#!/bin/bash

override_conjure_spec_files() {
    cat "$incdir/macros.go-rpm" "$specdir/$specfile" \
        > "$builddir/$specfile"
}

override_post_install_deps() {
    sudo alternatives --set python /usr/bin/python2
}

. "${0%/*}"/../../build-env/inc/rpm-common.sh
