#!/bin/bash
# Convert a set of Debian packages into a portable tarball.
# See `deb2tar.sh --help'.

set -e
shopt -s globstar failglob

# split(SEP, EXPR) - splits the string EXPR into a list of
# strings. Anything in EXPR that matches SEP is taken to be a
# separator.
split() {
    local IFS=$'\1'
    eax=(${2//"$1"/"$IFS"})
}

# join(SEP, LIST) - joins the separate strings of LIST into a single
# string with fields separated by the value of SEP.
join() {
    local IFS="$1"; shift
    eax=$*
}

# back_to_root(EXPR) - for a relative path EXPR computes a path back to
# the directory it is relative to.
back_to_root() {
    eax=${1//[^\/]}
    eax=${eax//\//../}
    eax=${eax%/}
}

# relink(EXPR) - if the file EXPR is an absolute symbolic link, makes
# the link relative to the base directory of EXPR.
relink() {
    local link rlink
    link=$(readlink "$1")

    if [[ $link == /* ]]; then
        back_to_root "$1"; rlink=${eax}/${link#/}
        echo "- relink $1: FROM $link TO $rlink"
        ln -snf "$rlink" "$1"
    fi
}

# fix_shebang(EXPR) - if a script whose filename is given by EXPR has
# an interpreter other than /bin/sh or /usr/bin/env, fix_shebang tries
# to substitute it by /usr/bin/env + the name of the original
# interpreter. This only works if the original shebang line didn't
# have a parameter.
fix_shebang() {
    local hdr interp

    read -r hdr <"$1"
    hdr=(${hdr#'#!'})
    [[ ${#hdr[@]} -lt 1 ]] && return 0 # no interpreter after shebang

    interp=${hdr[0]}
    [[ $interp == "/bin/sh" ]]      && return 0 # assuming bash scripts don't
    [[ $interp == "/usr/bin/env" ]] && return 0 # hide as sh ones...

    if [[ ${#hdr[@]} -gt 1 ]]; then
        echo "Error: unable to fix the shebang of $1: '#!${hdr[*]}' (parameter '${hdr[1]}' will be lost)"
        return 1
    fi

    interp=${interp##*/}
    echo "- fix_shebang $1 FROM '${hdr[0]}' TO '/usr/bin/env $interp'"
    sed -ie '1c\#!/usr/bin/env '"$interp" "$1"
}

# elf_p(EXPR) - checks if the file EXPR is an ELF file.
elf_p() {
    IFS= read -rn4 hdr <"$1" && \
    [[ $hdr == $'\x7f'ELF ]]
}

# script_p(EXPR) - checks if the file EXPR is a script with a shebang.
script_p() {
    IFS= read -rn2 hdr <"$1" && \
    [[ $hdr == "#!" ]]
}

# executable_p(EXPR) - checks if the file EXPR is executable and not a
# dynamic library.
executable_p() {
    local f="$1"
    local hdr

    [[ -f $f ]] && [[ -x $f ]] && \
    [[ ! $f == *.so   ]]       && \
    [[ ! $f == *.so.* ]]
}

# sh_escape(EXPR) - converts the string EXPR in a format that can be
# used as shell input.
sh_escape() {
    eax=$(printf '%q' "${1-$eax}")
}

# wrapelf(EXPR, LDPATH) - if the file whose filename is given by EXPR
# is a dynamic ELF executable, creates a shell script which executes
# this file using a bundled loader. Only glibc's loader is supported.
#
# LDPATH is a string of colon-separated directories in which the
# shared libraries this executable depends on will reside at run time.
wrapelf() {
    local f libdirs path_to_root elfinfo cld
    f=$1

    elfinfo=$(readelf -l "$f")
    [[ $elfinfo =~ "program interpreter: "(.*?)"]" ]] || return 0
    sh_escape "${BASH_REMATCH[1]}"; cld=$eax

    echo "- wrapelf $f"
    mv "$f" "${f}.elf"
    back_to_root "$f"; path_to_root=$eax

    libdirs=(/usr/lib/pelion /lib64 /lib /lib/"$DEB_HOST_GNU_TYPE" /usr/lib/"$DEB_HOST_GNU_TYPE")
    join ':' "${libdirs[@]/#/"\$root"}"; libdirs=$eax

    cat >"$f" <<EOF
#!/bin/sh
root=\${0%/*}/$path_to_root
exec "\$root"$cld --library-path "$libdirs" "\$0.elf" "\$@"
EOF

    chmod +x "$f"
}

# fetch_deps(LIST) - scans for dependencies of all Debian packages
# provided in LIST and downloads them to the current working directory.
fetch_deps() {
    local host="$DEB_HOST_ARCH"
    local -A deps

    local -a rewrite=(
        '/^debconf/d'
        '/^dpkg/d'
        '/^tar\b/d'
        '/^perl-base\b/d'
        '/^base-files\b/d'
        '/^awk\b/d'
        's/^(libldap-common):.*/\1:all/'
    )

    local -a append=(
        'util-linux'
        'bsdutils'
    )

    local f
    for f in "$@"; do
        split ", " "$(dpkg-deb -W --showformat '${Depends}' "$f")"
        for x in "${eax[@]}"
        do deps[${x%% *}]=""
        done
    done

    join ';' "${rewrite[@]}"; rewrite=$eax

    local pkg
    apt-rdepends "${!deps[@]}" "${append[@]}" |\
    sed -E "/^ /d; s/.*/\0:$host/; $rewrite"  |\
    xargs apt-get download
}

usage=$(cat <<EOF
${0##*/} - converts a set of Debian packages into a portable tarball.

Usage: ${0##*/} [-h|--help] [-a ARCH|--arch ARCH]
 -h, --help
  Display this help message.
 -a ARCH, --arch ARCH
  Set the host architecture of the tarball.
EOF
)

opts=$(getopt -n "$0" -o 'ha:' -l 'help,arch:' -- "$@")
eval set -- "$opts"
while true; do
    case "$1" in
        -h|--help)
            echo "$usage" && exit 0 ;;
        -a|--arch)
            host=$2
            shift 2 ;;
        --) shift && break ;;
        *)  printf "%s\n%s\n" "$0: invalid arguments" "$usage"
            exit 2 ;;
    esac
done

eval "$(dpkg-architecture -s ${host:+--host-arch="$host"})"

cwd=$(pwd)
cd "${0%/*}/../.."
topdir=$(pwd)
deploydir=$topdir/build/deploy/tar
tarname=pelion-edge-$DEB_HOST_ARCH
distro=bionic/main
tarfile=$tarname.tar.gz
workdir=$(mktemp -d)
moshpit=$workdir/$tarname
downloads=$workdir/downloads
pkgs=("$topdir"/build/deploy/deb/"$distro"/binary-"$DEB_HOST_ARCH"/*.deb)

echo "Downloading dependencies..."
mkdir -p "$moshpit" "$downloads"
cd "$downloads"
fetch_deps "${pkgs[@]}"

echo "Extracting Debian packages..."
for pkg in "${pkgs[@]}" "$downloads"/*.deb; do
    mkdir -p "$workdir/ar_x" && cd "$_"

    echo "- ar x $pkg"
    ar x "$pkg"
    mkdir data

    case "${pkg##*/}" in
        mbed-edge-core-devmode*)
            tar -xf data.tar.* -C data
            mv data/usr/bin/edge-core{,-devmode}
            mv data/lib/systemd/system/edge-core{,-devmode}.service ;;
        util-linux*) tar -xf data.tar.* -C data ./usr/bin/flock     ;;
        bsdutils*)   tar -xf data.tar.* -C data ./usr/bin/script    ;;
        *)           tar -xf data.tar.* -C data                     ;;
    esac

    cp -r data/* "$moshpit/"
    cd "$workdir" && rm -rf ar_x
done

rm -rf "$downloads"
cd "$moshpit"
cp -a "$topdir"/tarball/* .

echo "Copying root certificates..."
mkdir -p etc/ssl/certs
cp /etc/ssl/certs/ca-certificates.crt ./etc/ssl/certs

echo "Scanning the resulting file tree for problems..."
for f in **; do
    if [ -h "$f" ]; then
        links+=("$f")
    elif executable_p "$f"; then
        if elf_p "$f";      then elves+=("$f")
        elif script_p "$f"; then scripts+=("$f")
        fi
    fi
done

echo "Fixing symbolic links..."
for f in "${links[@]}"; do
    relink "$f"
done

echo "Fixing shebangs..."
for f in "${scripts[@]}"; do
    fix_shebang "$f"
done

echo "Gift-wrapping elves... 🎁"
for f in "${elves[@]}"; do
    wrapelf "$f"
done

echo "Applying patches..."
quilt push -a

echo "Compressing archive..."
mkdir -p "$deploydir"
cd "$workdir"
echo "- tar cf $deploydir/$tarfile"
tar -caf "$deploydir/$tarfile" "$tarname"

cd "$cwd"
rm -rf "$workdir"
