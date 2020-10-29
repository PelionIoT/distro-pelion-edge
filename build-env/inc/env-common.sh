OVERRIDE_BIN_PATH=/opt/bin

export PATH=${OVERRIDE_BIN_PATH}:${PATH}:/usr/lib/pe-golang/bin:/usr/lib/pelion/bin

# link python to python2 or python3 in $OVERRIDE_BIN_PATH dir
# arg: 2 or 3
function select_python()
{
    local PY=$(which python"$1")

    if [ $? -ne 0 ];then
        echo "ERROR: cannot find python"$1" in PATH"
        return 1
    fi

    if ! stat $OVERRIDE_BIN_PATH >/dev/null 2>&1; then
        sudo mkdir -p $OVERRIDE_BIN_PATH
    fi

    echo "Selecting python"$1" as default python interpreter"
    sudo ln -fs $PY $OVERRIDE_BIN_PATH/python
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
