#!/bin/bash
source ${BASH_SOURCE[0]%/*}/../inc/build-all/runner.sh

opt_usage="${0##*/} - build all packages:

USAGE: 
-a, --arch=<name>       run build for <name> architecture
-d, --docker=<name>     run build in docker (name=docker environment)
-h, --help              print this help text
-i, --install           install dependencies
-e, --print-env=[what]  print environment setup: packages, meta, deps
                        (deps packages)
-l, --print-list        print list: env (list of available environments)
-c, --container=[opts]  use one container per kind instead of container
                        per package; opts can be (comma separated):
                        - clean - create new container before first use
-r, --recreate          forcibly recreate docker images (implies -c=clean)

Build elements:
-b, --build             run build stage
-s, --source            run source stage
-t, --tar               run tarball creation stage
-p, --deps              run dependency compilation stage

When no -b, -s, -t or -p are set, all are enabled. Setting one of them will
disable unset parameters (eg. setting -b -s will run only source and build
stage).

If --docker is set, build process will run in new container. By adding --container
scripts will use one container to build all packages (instead of container
per package)"

opt_short_opts='a:d:hil:e:bstpc::r'
opt_long_opts='arch:,docker:,container::,recreate,help,install,print-list:,print-env:,build,source,tar,deps'
opt_dispatch=parse_build_all_options

# default settings:
arg_install=false
arg_source=false
arg_build=false
arg_tar=false
arg_deps=false
arg_recreate=false

function parse_build_all_options {
    while true; do
        case "$1" in
            -h|--help)          echo "$opt_usage" && exit 0;;
            -i|--install)       arg_install=true; shift;;
            -s|--source)        arg_source=true; shift;;
            -t|--tar)           arg_tar=true; shift;;
            -b|--build)         arg_build=true; shift;;
            -p|--deps)          arg_deps=true; shift;;
            -d|--docker)        arg_docker="$2"; shift 2;;
            -c|--container)     arg_container="$2"; shift 2;;
            -r|--recreate)      arg_recreate=true; shift;;
            -a|--arch)          arg_arch="$2"; shift 2;;
            -e|--print-env)     arg_print_env=( print_env "$2" ); shift 2;;
            -l|--print-list)    arg_print_list=( print_list "$2" ); shift 2;;
            --) shift
                if [ $# -gt 0 ];then
                    printf "%s\n\n%s\n" "${0##*/}: unused arguments: $*" "$opt_usage"
                    exit 2
                fi
                break;;

            *) echo skipping unimplemented: $1; shift;;
        esac
    done

    # postprocess switches: enable all if none was set in command line
    if ! $arg_build && ! $arg_source && ! $arg_tar && ! $arg_deps; then
        arg_build=true
        arg_source=true
        arg_tar=true
        arg_deps=true
    fi
}

# print for non-env data:
# - env
function print_list {
    case "$1" in
        env*)
            if ! list=$(env_list); then
                exit 1
            fi

            echo $list ;;
        *)
            echo "unknown list: $1"
            exit 1
    esac
}

# print list packages and deps (env data)
# - meta
# - packages
# - deps
function print_env {
    case "$1" in
        meta*)
            echo ${METAPACKAGES[@]};;

        packages)
            echo ${PACKAGES[@]};;

        deps)
            echo ${DEPENDS[@]};;

        *)
            echo "unknown list: $1"
            exit 1
    esac
}

opt_parse_args "$@"

# print non-env data (needed for unsupported host build os)
if [ -v arg_print_list ]; then
    "${arg_print_list[@]}"
    exit 0
fi

# prepare variables which needs access to environment
opt_postprocess_arch

# load environment
if [ -v arg_docker ];then
    env_load_by_name "$arg_docker"
else
    env_load_by_os
fi

# run printers if set and exit (for env data)
if [ -v arg_print_env ]; then
    "${arg_print_env[@]}"
    exit 0
fi

# go to root: same for docker and native build
cd $ROOT_DIR

echo ">>> starting build <<<"

if $arg_deps && [ -v DEPENDS ]; then
    for ARCH in "${opt_deps_arch[@]}"; do
        echo ">> building dependencies for $ARCH"
        LOG_STR=">> building %s source package" run_group DEPENDS run_source_deps
        LOG_STR=">> building %s binary package" run_group DEPENDS run_build_deps
        LOG_STR=">> deploying %s dependency packages" run_group DEPENDS run_deploy_deps
    done
fi

if $arg_source; then
    for ARCH in "${opt_build_arch[@]}"; do
        echo ">> building source packages for $ARCH"
        LOG_STR=">> building %s source package" run_group PACKAGES run_source
    done
fi

if $arg_build; then
    for ARCH in "${opt_build_arch[@]}"; do
        echo ">> building binary packages for $ARCH"
        LOG_STR=">> building %s binary package" run_group PACKAGES run_build
    done

    if [ -v METAPACKAGES ]; then
        for ARCH in "${opt_meta_arch[@]}"; do
            echo ">> building metapackages using $ARCH"
            LOG_STR=">> building %s metapackage" run_group METAPACKAGES run_build_metapackage
        done
    fi

    # Verification 
    for ARCH in "${opt_build_arch[@]}"; do
        echo ">> verifying binary packages for $ARCH"
        LOG_STR=">> verifying %s binary package" run_group PACKAGES run_verify
    done

    if [ -v METAPACKAGES ]; then
        for ARCH in "${opt_meta_arch[@]}"; do
            echo ">> verifying metapackages using $ARCH"
            LOG_STR=">> verifying %s metapackage" run_group METAPACKAGES run_verify_metapackage
        done
    fi

fi

if $arg_tar; then
    for ARCH in "${opt_build_arch[@]}"; do
        echo ">> building tarball for $ARCH"
        run_tar_build
    done
fi

echo ">>> build finished <<<"

