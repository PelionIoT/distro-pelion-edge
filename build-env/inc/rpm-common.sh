#!/bin/bash

REAL_BASH_SOURCE=$(readlink -m ${BASH_SOURCE[0]})
source ${REAL_BASH_SOURCE%/*}/../inc/build-all/runner.sh

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
             -D"_filesdir     $cwd/files" \
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

# called after dependency installation
function post_install_deps {
    :
}

# Install BuildRequires packages
function install_deps() {
    local file="$specdir/$specfile"
    cat $file
    if grep '^BuildRequires:' $file ; then
        sudo yum-builddep -y --spec $file
    fi

    dispatch post_install_deps
}

# Creates a source archive from a downloaded repository. If the
# download rule was overriden, this one should probably be too.
# Overridable.
conjure_sources() {
    local name="${1-$tarname}"
    local ver="${2-$tarver}"
    cd "$cachedir/$name"
    tar --xform "s#^\./#$name-$ver/#" \
         -cf "$builddir/$name-$ver.tar.gz" .
}

# Copy files/* to builddir
# links will be dereferenced
conjure_files() {
    cd "$specdir"
    if [ -d files ]; then
        cp -Lrf files "$builddir"
    fi
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
    rpmbuild_here "${@:--ba}" "$specfile"
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
    $arg_install && dispatch install_deps
    dispatch conjure_sources
    dispatch conjure_spec_files
    dispatch conjure_files
    dispatch conjure_patches
    dispatch assemble $rpmbuild_args
    dispatch deploy
}

# command line parameters - defaults
arg_install=false # install dependencies
arg_build=false # build binary package
arg_source=false # build source package
arg_recreate=false # recreate container

opt_usage="${0##*/} - builds $package RPM package

Usage: ${0##*/} [-h|--help] [--install]
 -h, --help                 display this help message.
 -i, --install              install dependencies
 -b, --build                build package
 -s, --source               prepare sources
 -d, --docker=<name>        use docker container to build RPM
 -a, --arch=<name>          build for selected architecture
 -c, --container=[opts]     reuse container; opts can be (comma separated):
                            - clean - create new container before first use
 -r, --recreate             forcibly recreate docker images (implies -c=clean)
 -o, --deploy=<path>        set target directory for RPMs
"

parse_args() {
while true; do
    case "$1" in
        -h|--help)      echo "$opt_usage" && exit 0 ;;
        -i|--install)   arg_install=true; shift;;
        -b|--build)     arg_build=true; shift;;
        -s|--source)    arg_source=true; shift;;
        -d|--docker)    arg_docker=$2; shift 2;;
        -a|--arch)      arg_arch="$2"; shift 2;;
        -c|--container) arg_container="$2"; shift 2;;
        -r|--recreate)  arg_recreate=true; shift;;
        -o|--deploy)    arg_deploy="$2"; shift 2;;
        --) shift
            if [ $# -gt 0 ];then
                printf "%s\n\n%s\n" "${0##*/}: unused arguments: $*" "$opt_usage"
                exit 2
            fi
            break ;;
        *)  printf "%s\n%s\n" "$0: invalid arguments" "$usage"
            exit 2 ;;
    esac
done

# set proper build flags
if $arg_build && $arg_source; then
    rpmbuild_args=-ba
elif $arg_build; then
    rpmbuild_args=-bb
elif $arg_source; then
    rpmbuild_args=-bs
else
    rpmbuild_args=-ba
fi

if [ -v arg_arch ] && [ ! -v arg_docker ]; then
    echo "--arch can be used only with --docker"
    exit 1
fi

}

opt_dispatch=parse_args
opt_short_opts='hibsa:d:c::d:r'
opt_long_opts='help,install,build,source,arch:,docker:,container::,deploy:,recreate'

dispatch opt_parse_args "$@"

# prepare variables which needs access to environment
opt_postprocess_arch

# load docker environment and run script inside
if [ -v arg_docker ];then
    env_load_by_name "$arg_docker"
else
    env_load_by_os
fi

cd "${0%/*}"
specdir=$(pwd)
package=$(pkgname_from_specdir "$specdir")
tarname=$package
tarver=master
topdir=$specdir/../..
incdir=$topdir/build-env/inc
cachedir=$topdir/build/downloads/$package
builddir=$topdir/build/tmp-build/$package/rpm
distname=${DISTNAME:-}
deploydir=${arg_deploy:-$topdir/build/deploy/rpm/$distname}
specfile=$package.spec
buildscript=$(realpath -s "${0##*/}" --relative-to="$topdir")

# load docker environment and run script inside
if [ -v arg_docker ];then
    for ARCH in "${arg_arch[@]}"; do
        args=( )
        if $arg_build; then
            args+=( --build )
        fi

        if $arg_source; then
            args+=( --source )
        fi

        if $arg_install; then
            args+=( --install )
        fi

        if [ -v arg_deploy ]; then
            args+=( --deploy="$arg_deploy" )
        fi

        run_command_build $buildscript ${args[@]}
    done
else
    rm -rf "$builddir"
    mkdir -p "$cachedir"
    mkdir -p "$builddir"
    mkdir -p "$deploydir"
    dispatch all
fi
