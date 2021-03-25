
# set scripts root dir
ROOT_DIR=$(cd "`dirname \"$0\"`"/../../.. && pwd)

# sets if available, sets empty if not
# - OS_VERSION_ID
# - OS_VERSION_CODENAME
# - OS_ID
function opt_resolve_host_distro {
    local osfile=/etc/os-release
    if [ -f $osfile ];then
        OS_VERSION_ID=$(source $osfile; echo $VERSION_ID)
        OS_VERSION_CODENAME=$(source $osfile; echo $VERSION_CODENAME)
        OS_ID=$(source $osfile; echo $ID)
    else
        # TODO: handling unknown os: we do not have to fail if we are just hosting docker
        echo "WARNING: no /etc/os-release"
        OS_VERSION_ID=
        OS_VERSION_CODENAME=
        OS_ID=
    fi
}

# list of short options (getopt)
opt_short_opts='hi'
# list of long options (getopt)
opt_long_opts='help,install'
# filtered arguments parser
opt_dispatch=echo

# parse arguments using getopt. Uses opt_usage, opt_short_opts, opt_long_opts, opt_dispatch
# arg1-N: command line arguments
opt_parse_args() {
    local -a opts;

    if ! opts=( $(getopt -n "$0" -a -o "$opt_short_opts" -l "$opt_long_opts" -- "$@") ); then
        $opt_dispatch --help
        return 1;
    fi

    eval opts=( "${opts[@]}" )

    $opt_dispatch "${opts[@]}"
}


# get current arch, exit if not supported
function opt_current_arch {
    case "$(uname -m)" in
            x86_64) echo amd64 ;;
            aarch64) echo arm64 ;;
            armv7l) echo armhf ;;
            *) exit 1 ;;
    esac
}

# TODO: reuse split (IFS=, function) from here, if needed

# prepare arg_arg variable (split). Checks if arch(s) are supported
# should be done in env_load, this should be called before loading env
# ENV uses:
# - arg_arch - comma-separated list of architectures to perform build
# ENV sets:
# - opt_build_arch - array of architectures to build packages for
# - opt_deps_arch - array of architectures to build dependency packages
# - opt_meta_arch - array of architectures to do meta packages build
# by default all are set to all architectures as in arg_arch, or to
# current system arch if arg_arch is not set
function opt_postprocess_arch {
    local IFS=,
    arg_arch=($arg_arch)

    if [ "${#arg_arch[@]}" -eq 0 ]; then
        if ! ARCH=$(opt_current_arch); then
            echo "Unable to determine current architecture"
            exit 1
        fi

        arg_arch=( "$ARCH" )
    fi

    opt_deps_arch=( ${arg_arch[@]} )
    opt_meta_arch=( ${arg_arch[@]} )
    opt_build_arch=( ${arg_arch[@]} )
}

# get list of all selected architectures
# simply gets opt_*_arch and prints unique elements
function opt_get_all_selected_arch {
    local -a allarch=($(printf  "%s\n"  "${opt_build_arch[@]}" \
                                        "${opt_meta_arch[@]}" \
                                        "${opt_deps_arch[@]}" | sort -u ))
    echo "${allarch[@]}"
}

