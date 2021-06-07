source $ENV_TARGET_ROOT/common/debian_packages.conf.sh

ENV_OS_NAME=buster

function docker_image_create {
    ENVDIR=$(dirname ${BASH_SOURCE[0]})

    # TODO: remove scripts, use function like in rhel
    $ROOT_DIR/build-env/bin/docker-debian-buster-create.sh
}

function env_match_current {
    [ "$OS_ID" == 'debian' ] && [[ "$OS_VERSION_ID" =~ 10 ]]
}
