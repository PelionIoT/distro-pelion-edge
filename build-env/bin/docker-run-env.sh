#!/usr/bin/env bash

source ${BASH_SOURCE%/*}/../inc/build-all/runner.sh

opt_usage="${0##*/} - run commands in environment containers

SYNTAX:
 ${0##*/} [options] <environment-name> [command...]

First positional argument stops parsing options.
Environment name accepts partial name match

Options cannot be joined (eg -rc is not supported)


OPTIONS:
 -a, --arch=<name>       run commands using env setup for <name> architecture
 -h, --help              print this help text
 -c, --container=[opts]  use one container per kind instead of container
                         per package; opts can be (comma separated):
                         - clean - create new container before first use
 -r, --recreate          forcibly recreate docker images (implies -c=clean)

Architecture is set according to selected environment: using non-host architecture
may use host architecture anyway - depending on environment (for cross-compiling
environments like Debian/Ubuntu, --arch will be ignored).

EXAMPLES:

1. run new rhel/8 image for host arch:
 ${0##*/} rhel

2. run centos container (attach to existing)
 ${0##*/} -c centos

3. run 'ls' in centos container
 ${0##*/} -c centos ls

4. run fresh container (and allow later attaching to it)
 ${0##*/} -c clean centos ls

5. recreate image and container and run shell in new container
 ${0##*/} -r -c clean centos

6. run new arm64 container
 ${0##*/} -c=clean -a arm64 centos

"

arg_recreate=false
arg_arch=( $(opt_current_arch) )

while true; do
    case "$1" in
        -a|--arch)
            arg_arch=( $2 ); shift 2;;

        -a=*|--arch=*)
            arg_arch=( ${1#*=} ); shift 1;;

        -c|--container)
            arg_container=
            if [[ ! $1  =~ ^- ]]; then
                arg_container=$2
                shift
            fi
            shift ;;

        -c=*|--container=*)
            arg_container=${1#*=}
            shift 1;;

        -r|--recreate)
            arg_recreate=true; shift ;;

        -h|--help)
            echo "$opt_usage"
            exit 0 ;;
        *)
            arg_docker=$1; shift
            break ;;
    esac
done


opt_postprocess_arch
env_load_by_name "$arg_docker"

# selecting architecture
ARCH=${arg_arch[0]}
PLATFORM_ARCH=linux/$ARCH
DOCKER_OPTS=${DOCKER_OPTS:--it}

run_command_source "${@-bash}"
