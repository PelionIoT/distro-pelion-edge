#!/bin/bash

set -e
shopt -s nullglob

spec_url() {
    awk <"$1" \
        -e '/^%global forgeurl\>/ { print            $3; exit }' \
        -e '/^%global goipath\>/  { print "https://" $3; exit }'
}

spec_ver() {
    awk <"$1" \
        -e '/^Version:/               { print $2; exit }' \
        -e '/^%global (commit|tag)\>/ { print $3; exit }'
}

rpmbuild_here() {
    local cwd="$(pwd)"
    rpmbuild -D"_topdir       $cwd" \
             -D"_sourcedir    $cwd" \
             -D"_specdir      $cwd" \
             -D"_builddir     $cwd" \
             -D"_srcrpmdir    $cwd" \
             -D"_buildrootdir $cwd" \
             -D"_rpmdir       $cwd" "$@"
}

pkgname_from_specdir() {
    local IFS=/
    set -- $1
    printf %s "${@: -2: 1}"
}

# Extracts a file name from a repository URL.
url_filename() {
    local url="${1##*/}"
    echo "${url%.git}"
}

# Downloads a repository and it's submodules.
git_clone_r() {
    local url commit dir
    url=$1; commit=$2; dir=$3

    if [ ! -d "$dir" ]; then
        git clone "$url" "$dir"
    fi

    cd "$dir"
    git checkout "$commit"
    if [ -f ".gitmodules" ]; then
        git submodule update --init --recursive
    fi
    cd ..
}

# Checks if the argument is a command.
commandp() {
    command -v "$1" &>/dev/null
}

# Checks if a python package is installed.
check_python_dep() {
    if ! commandp python3; then
        echo "Error: python3 is not installed."
        exit 1
    fi

    if ! python3 -c "import $1" 2>/dev/null; then
        echo "Error: the python package \"$1\" is required, but not installed."
        echo "Try \"dnf install python3-$1\" or \"pip-3 install $1\"."
        exit 1
    fi
}

# Calls an overridable function.
dispatch() {
    local cmd ovr
    cmd=$1; ovr=override_$1
    shift

    if commandp "$ovr"
    then "$ovr" "$@"
    else "$cmd" "$@"
    fi
}

cd "${0%/*}"
specdir=$(pwd)
package=$(pkgname_from_specdir "$specdir")
tarname=$package
tarver=master
topdir=$specdir/../..
incdir=$topdir/build-env/inc
cachedir=$topdir/build/downloads
builddir=$topdir/build/tmp-build/$package/rpm
deploydir=$topdir/build/deploy/rpm
specfile=$package.spec

rm -rf "$builddir"
mkdir -p "$cachedir"
mkdir -p "$builddir"
mkdir -p "$deploydir"

# Downloads a source repository into $cachedir.
# Overridable.
download() {
    cd "$cachedir"
    if [ $# -gt 0 ]; then
        git_clone_r "$1" "${2-master}" "${3-$(url_filename "$1")}"
    else
        local forgeurl
        forgeurl=$(spec_url "$specdir/$specfile")
        tarname=$(url_filename "$forgeurl")
        tarver=$(spec_ver "$specdir/$specfile")
        git_clone_r "$forgeurl" "$tarver" "$tarname"
    fi
}

# Creates a source archive from a downloaded repository. If the
# download rule was overriden, this one should probably be too.
# Overridable.
conjure_sources() {
    local name="${1-$tarname}"
    local ver="${2-$tarver}"
    cd "$cachedir/$name"
    tar --xform "s/^\./$name-$ver/" \
         -cf "$builddir/$name-$ver.tar.gz" .
}

# Copies RPM spec files from $specdir into $builddir.
# Overridable.
conjure_spec_files() {
    cd "$specdir"
    cp "$specfile" "$builddir/"
}

# Copies patches from $specdir into $builddir.
# Overridable.
conjure_patches() {
    cd "$specdir"
    for f in *.patch; do
        cp "$f" "$builddir"/
    done
}

# Creates binary and source RPMs from the contents of $builddir.
# Overridable.
assemble() {
    cd "$builddir"
    rpmbuild_here -ba "$specfile"
}

# Copies RPM files from $builddir into $deploydir.
# Overridable.
deploy() {
    cd "$builddir"
    find -depth -name '*.rpm' -print0 \
        | cpio -pvd0 "$deploydir"
}

# Calls all of the above steps in sequence.
# Overridable.
all() {
    dispatch download
    dispatch conjure_sources
    dispatch conjure_spec_files
    dispatch conjure_patches
    dispatch assemble
    dispatch deploy
}

dispatch all
