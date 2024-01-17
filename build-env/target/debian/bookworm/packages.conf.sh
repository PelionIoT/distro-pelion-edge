source $ENV_TARGET_ROOT/common/debian_packages.conf.sh

DEPENDS=(
    'golang-providers/pe-golang-bin'
)

ENV_OS_NAME=bookworm

function docker_image_create {
    ENVDIR=$(dirname ${BASH_SOURCE[0]})

    # TODO: remove scripts, use function like in rhel
    $ROOT_DIR/build-env/bin/docker-debian-bookworm-create.sh
}

function env_match_current {
    [ "$OS_ID" == 'debian' ] && [[ "$OS_VERSION_ID" =~ 11 ]]
}
