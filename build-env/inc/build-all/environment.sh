
#########################################
# interface - to be implemented per ENV: #
#########################################
# return true if current environment is matching environment settigs
# available env (vars from /etc/os-release prefixed with OS_):
# - OS_VERSION_ID
# - OS_VERSION_CODENAME
# - OS_ID
function env_match_current {
    ! :
}

# load environment
# This function is responsible for setting up
# variables to provide work possibility
# in supported architectures
# do NOT use docker here
function env_load {
    :
}

function env_load_post {
    :
}


# load environment: docker part (step which requires functioning docker)
# this part will be called after env_load before each docker run/create calls
# this callback can be used to do preparation which requires docker
# (eg. preparation of repository volume)
# this cannot use container - can use docker_run_image only!
function env_load_docker {
    :
}

# true if arch is supported
# arg1: arch to check
function env_arch_supported {
    :
}

# list of packages to build for current env
PACKAGES=( )

# list of metapackages to build for current env
METAPACKAGES=( )

# list of dependency package (to be build and installed before building PACKAGES)
DEPENDS=( )

#########################################
# library functions                     #
#########################################
ROOT_DIR=$(cd "`dirname \"$0\"`"/../.. && pwd)

# root directory for targets envs
ENV_TARGET_ROOT="$ROOT_DIR"/build-env/target
ENV_SETUP_SCRIPT=packages.conf.sh
# TODO: packages is not good name for config


# load environment by name. It will replace -,:,/ with space and try to match words in
# order with supported environments. Will fail when there are more than one match.
# order of resolution:
# 1. match 'as is'
# 2. remove separators, match words in order
# arg1: env name (eg. focal, ubuntu-focal, ubuntu/focal, ubuntu:focal, debian-buster)
function env_load_by_name {
    local -a envs=( $(env_list) )
    local -a matches=( )
    local name="$1"

    # exact match
    for E in "${envs[@]}"; do
        if [ "$name" == "$E" ];then
            matches+=("$E")
        fi
    done

    if [ ${#matches[@]} -eq 1 ];then
        env_load_from ${matches[0]}
        return 0
    fi

    # fuzzy match
    local -a tokens=( $(echo "$name" | sed 's/[\/\:/\-]/ /') )

    for E in "${envs[@]}"; do
        local got_match=true

        for token in "${tokens[@]}"; do
            if [[ ! "$E" =~ "$token" ]];then
                got_match=false
            fi
        done

        if $got_match; then
            matches+=("$E")
        fi
    done

    if [ ${#matches[@]} -gt 1 ];then
        echo "Unable to load environment: ambiguous environment name, matches:"
        echo "${matches[@]}"
        return 2
    fi

    if [ ${#matches[@]} -eq 0 ];then
        echo "Unable to load environment: no match for \"$name\""
        return 3
    fi

    env_load_from ${matches[0]}
    return 0
}

# load environment from name
# arg1: exact name to load (in path form eg. ubuntu/focal, rhel/8)
# uses:
# - arg_container
# - arg_recreate
# - arg_arch
function env_load_from {
    source "$ENV_TARGET_ROOT"/"$1"/$ENV_SETUP_SCRIPT
    env_load
    env_prepare_containers build
    env_prepare_containers source
    env_load_post
}

function env_prepare_containers {
    local ARCH
    for ARCH in $(opt_get_all_selected_arch); do
        if ! env_arch_supported $ARCH; then
            echo "Architecture '$ARCH' is not supported for selected environment"
            return 1
        fi

        # prepare docker container
        if [ "$arg_container" == "clean" ] || $arg_recreate && docker_container_available "$1"; then
            docker_container_remove "$1"
        fi

        if $arg_recreate; then
            docker_image_remove "$1"
        fi

    done
}

# load environment for current os
# functions gets os-release details and matches with supported envs
function env_load_by_os {
    # 1. identify current os, set to local variables to avoid global scope pollution
    local OS_VERSION_ID
    local OS_VERSION_CODENAME
    local OS_ID
    opt_resolve_host_distro

    # 2. iterate over all supproted envs and match with current (env_match_current) - run in sub shell!
    # on match - run env_load_from in current shell
    local -a envs=( $(env_list) )
    local result

    for env in ${envs[@]}; do
        if result=$(env_load_from $env; env_match_current); then
            echo "Using \'$env\' setup"
            env_load_from $env
            return 0
        fi
    done

    echo "Unable to load matching env config for your system"
    return 1
}

# get list of env's names
function env_list {
    if [ ! -v ENV_LIST ]; then
        ENV_LIST=( $(find "$ENV_TARGET_ROOT" -name $ENV_SETUP_SCRIPT -not -path '*/.*' -printf '%P\n' -type f | xargs -L1 dirname) )
    fi

    echo "${ENV_LIST[@]}"
}

