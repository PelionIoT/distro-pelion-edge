source $ENV_TARGET_ROOT/common/debian_packages.conf.sh

DEPENDS=(
    'golang-providers/pe-golang-bin'
    'pe-nodejs'
)

ENV_OS_NAME=bionic

function env_match_current {
    [ "$OS_ID" == 'ubuntu' ] && [[ "$OS_VERSION_ID" =~ ^18.04 ]]
}

function docker_image_create {
    ENVDIR=$(dirname ${BASH_SOURCE[0]})

    # TODO: remove scripts, use function like in rhel
    $ROOT_DIR/build-env/bin/docker-ubuntu-bionic-create.sh
}
