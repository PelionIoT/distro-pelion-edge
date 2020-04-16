#!/bin/bash

override_conjure_spec_files() {
    cat "$incdir/macros.go-rpm" "$specdir/$specfile" \
        > "$builddir/$specfile"
}

. "${0%/*}"/../../build-env/inc/rpm-common.sh
