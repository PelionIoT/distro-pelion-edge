
# uses:
# - function docker_image_name_processed
# - function docker_image_run
# - function docker_image_ensure_created

source ${BASH_SOURCE%/*}/docker.sh
source ${BASH_SOURCE%/*}/options.sh
source ${BASH_SOURCE%/*}/environment.sh

set -e

################################
# interface function - per target

# run source build
# arg1: package name
function run_source {
    ! :
}

# arg1: package name
function run_build {
    ! :
}

# arg1: package name
function run_build_deps {
    run_build "$@"
}

# arg1: package name
function run_source_deps {
    run_source "$@"
}

# build metapackage, by default same as run_build but adds metapackages/ 
# prefix to the package path. Override per env if needed.
# arg1: package
# arg2-N: args passed to run_build
function run_build_metapackage {
    local PACKAGE=${1/#/metapackages\/}
    shift
    run_build $PACKAGE "$@"
}

# build tarball from all packages
function run_tar_build {
    ! :
}

# deploy packages to compilation env package repository
# install them if needed
function run_deploy_deps {
    :
}

# return package build script path (relative to repo ROOT)
# arg1: package name
function path_package_script {
    ! :
}

# logging helper
# printf "$LOG_STR\n" "$@" if LOG_STR is set
function run_log {
    if [ -v LOG_STR ]; then
        printf "${LOG_STR}\n" "$@"
    fi
}

###################################
# arg1: list of packages to build (deps, metapackages, packages)
# arg2: runner (eg. run_build, run_source)
# argN: optional args
function run_group {
    local -n packages=$1
    local runner=$2
    shift 2

    for package in "${packages[@]}"
    do
        run_log "$package"
        $runner $package "$@"
    done
}

# run in docker container (optionally reuse existing)
# or natively (depending on env options)
# arg1: docker image name (build, source)
# arg2-N: command to run with args
function run_command_generic {
    if [ -v arg_docker ]; then
        env_load_docker
        if [ ! -v arg_container ]; then
            docker_image_run "$@"
        else
            docker_container_run "$@"
        fi
    else
        shift
        "$@"
    fi
}

# TODO :cleanup ensure
# run commands in build container (actual build)
function run_command_build {
    run_command_generic build "$@"
}

# run commands in source container (source/source package preparation)
function run_command_source {
    run_command_generic source "$@"
}
