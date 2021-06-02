OVERRIDE_PYTHON_BIN_PATH=/opt/bin

export PATH=${OVERRIDE_PYTHON_BIN_PATH}:${PATH}:/usr/lib/pe-golang/bin:/usr/lib/pelion/bin

# link python to python2 or python3 in $OVERRIDE_PYTHON_BIN_PATH dir
# arg: 2 or 3
function select_python()
{
    local PY=$(which python"$1")

    if [ ! -n "$PY" ];then
        echo "ERROR: cannot find python"$1" in PATH"
        return 1
    fi

    if ! stat $OVERRIDE_PYTHON_BIN_PATH >/dev/null 2>&1; then
        sudo mkdir -p $OVERRIDE_PYTHON_BIN_PATH
    fi

    echo "Selecting python"$1" as default python interpreter"
    sudo ln -fs $PY $OVERRIDE_PYTHON_BIN_PATH/python
}

# depending on arg check if python2, python3 or python is in PATH
# arg: 2, 3 or no arg
function has_python() {
    PYTHON=$(which python"${1:-}")

    if [ $? -ne 0 ];then
        return 1
    fi

    return 0
}

# configure python
function configure_python()
{
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
