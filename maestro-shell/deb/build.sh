#!/bin/bash

# Internal variables
PELION_PACKAGE_NAME="maestro-shell"
PELION_PACKAGE_DIR=$(cd "`dirname \"$0\"`" && pwd)

#exported the branch so we can use it in auto_build script
export PACKAGE_BRANCH="2c90fbe2552c58ec5121b75a08718be6ebe5a791"

declare -A PELION_PACKAGE_COMPONENTS=(
    ["git@github.com:armPelionEdge/maestro-shell.git"]="$PACKAGE_BRANCH")

PELION_PACKAGE_PRE_BUILD_CALLBACK=pelion_maestro_shell_pre_build_cb

source "$PELION_PACKAGE_DIR"/../../build-env/inc/build-common.sh

function pelion_maestro_shell_pre_build_cb() {
    if $PELION_PACKAGE_INSTALL_DEPS; then
        # check python: use python3, python2 or install python3 if python is not installed
        if has_python;then
            return
        fi

        if has_python 3; then
            select_python 3;
            return
        fi

        if has_python 2; then
            select_python 2;
            return
        fi

        sudo apt install -y python3
        select_python 3
    fi
}

pelion_main "$@"
