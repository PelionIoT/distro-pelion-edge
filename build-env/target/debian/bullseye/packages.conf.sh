source $ENV_TARGET_ROOT/common/debian_packages.conf.sh

DEPENDS=(
    'golang-providers/pe-golang-bin'
    'pe-nodejs'
)

ENV_OS_NAME=bullseye

function docker_image_create {
    ENVDIR=$(dirname ${BASH_SOURCE[0]})

    # TODO: remove scripts, use function like in rhel
    $ROOT_DIR/build-env/bin/docker-debian-bullseye-create.sh
}

function env_match_current {
    [ "$OS_ID" == 'debian' ] && [[ "$OS_VERSION_ID" =~ 11 ]]
}
