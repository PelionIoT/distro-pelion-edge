#!/bin/bash

set -e

GPG_SCRIPT_DIR=$(cd "`dirname \"$0\"`" && pwd)

PELION_ROOT_DIR=$(cd "`dirname \"$0\"`"/../.. && pwd)
PELION_DEB_DEPLOY_DIR=$PELION_ROOT_DIR/build/deploy/deb

PELION_GPG_KEYNAME="Pelion_GPG_key"
PELION_GPG_KEYPATH=$PELION_DEB_DEPLOY_DIR/gpg

PELION_GPG_INSTALL=false

function pelion_gpg_key_parse_args() {
    for opt in "$@"; do
        case "$opt" in
            --key-name=*)
                PELION_GPG_KEYNAME="${opt#*=}"
                ;;

            --key-email=*)
                PELION_GPG_KEYEMAIL="${opt#*=}"
                ;;

            --key-path=*)
                PELION_GPG_KEYPATH="${opt#*=}"
                ;;

            --install)
                PELION_GPG_INSTALL=true
                ;;

            --help|-h)
                echo "Usage: $(basename "$0") --key-email=<email> [Options]"
                echo ""
                echo "Options:"
                echo " --key-name=<name>             Set name of GPG key and filename of public (<name>_public.gpg)"
                echo "                               and private (<name>_private.gpg) keys."
                echo " --key-email=<email>           Set email of GPG key."
                echo " --key-path=<path>             Set path where public and private keys will be placed."
                echo " --install                     Installs the necessary tools to generate the gpg key pair."
                echo " --help,-h                     Print this message."
                echo ""
                echo "Default mode: $(basename "$0") --key-name=$PELION_GPG_KEYNAME --key-path=$PELION_GPG_KEYPATH"
                exit 0
                ;;
        esac
    done
}

function pelion_gpg_key_generate() {
    mkdir -p "$PELION_GPG_KEYPATH"
    PELION_GPG_TMPDIR="$(mktemp -d -p "$PELION_GPG_KEYPATH")"

    echo "INFO: generating GPG key pair ..."

    cd "$PELION_GPG_TMPDIR/"

    cat > $PELION_GPG_KEYNAME.batch <<EOF
%no-protection
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $PELION_GPG_KEYNAME
Name-Email: $PELION_GPG_KEYEMAIL
Expire-Date: 0
EOF

    if [ $(gpg --version | grep 'gpg (GnuPG)' | sed -r 's/[^0-9]*([0-9]*).*/\1/') -eq 1 ]; then
        gpg --yes --gen-key --batch $PELION_GPG_KEYNAME.batch 2>&1 | tee GPG_output.log \
            || { echo "ERROR: Can not generate gpg keys. Check *.batch file!"; exit 1; }
    elif [ $(gpg --version | grep 'gpg (GnuPG)' | sed -r 's/[^0-9]*([0-9]*).*/\1/') -eq 2 ]; then
        gpg --yes --full-gen-key --batch $PELION_GPG_KEYNAME.batch 2>&1 | tee GPG_output.log \
            || { echo "ERROR: Can not generate gpg keys. Check *.batch file!"; exit 1; }
    else
        echo "ERROR: Unsupported gpg version!"
        exit 1
    fi

    PELION_GPG_KEYID=$(cat GPG_output.log | grep -P 'gpg: key [0-9A-F]{8,16} marked as ultimately trusted' | awk '{ print $3 }')

    if [ -z $PELION_GPG_KEYID ]; then
        echo "ERROR: key id not found in gpg generation output!"
        exit 1
    fi

    echo "INFO: exporting GPG key pair ..."

    rm -f "$PELION_GPG_KEYPATH/${PELION_GPG_KEYNAME}_public.gpg"
    rm -f "$PELION_GPG_KEYPATH/${PELION_GPG_KEYNAME}_private.gpg"

    gpg --output "$PELION_GPG_KEYPATH/${PELION_GPG_KEYNAME}_public.gpg" --export $PELION_GPG_KEYID

    if [ ! -s "$PELION_GPG_KEYPATH/${PELION_GPG_KEYNAME}_public.gpg" ]; then
        echo "ERROR: Can not export public gpg key with '$PELION_GPG_KEYID' key id!"
        exit 1;
    fi

    gpg --output "$PELION_GPG_KEYPATH/${PELION_GPG_KEYNAME}_private.gpg" --export-secret-key $PELION_GPG_KEYID

    if [ ! -s "$PELION_GPG_KEYPATH/${PELION_GPG_KEYNAME}_private.gpg" ]; then
        echo "ERROR: Can not export private gpg key with '$PELION_GPG_KEYID' key id!"
        exit 1;
    fi

    cd -
    rm -rf "$PELION_GPG_TMPDIR"
}

function pelion_gpg_key_main() {
    pelion_gpg_key_parse_args "$@"

    if [ -z $PELION_GPG_KEYEMAIL ]; then
        echo "ERROR: --key-email option is not set!"
        exit 1
    fi

    if $PELION_GPG_INSTALL; then
        sudo apt-get update && \
        sudo apt-get install -y gnupg
    fi

    pelion_gpg_key_generate

    echo "INFO: Done!"
}

# Entry point
pelion_gpg_key_main "$@"