#!/bin/bash
# ----------------------------------------------------------------------------
# Copyright (c) 2020, Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------------------
MBED_FOLDER=/var/lib/edge/mbed
MCC_CONFIG_FOLDER=$MBED_FOLDER/mcc_config
FCC_MODE=${FCC_MODE:-cbor}

CREDS_FOLDER=/var/lib/creds
CREDS_CBOR_FILE=$CREDS_FOLDER/device.cbor

if [ -e ${MCC_CONFIG_FOLDER} ]; then
    echo "mcc_config exists. Success!"
    exit 0
fi

cd $CREDS_FOLDER
export ENTROPYSOURCE=/dev/random

if [ "$FCC_MODE" == "cbor" ]; then
    if [ ! -f ${CREDS_CBOR_FILE} ]; then
        echo "edge-core launch failure: please verify $CREDS_CBOR_FILE"
        exit 1
    fi

    /usr/bin/factory-configurator-client-example.elf -f "$CREDS_CBOR_FILE"
elif [ "$FCC_MODE" == "tcp" ]; then

    /usr/bin/factory-configurator-client-example.elf
else
    echo "unknown client mode: \'$FCC_MODE\', use 'cbor' or 'tcp'"
fi

if [ ! -d $CREDS_FOLDER/pal/WORKING ]; then
	echo "/usr/bin/factory-configurator-client-example.elf did not generate a pal folder"
	exit 1
fi

FILE_COUNT=$(ls -A $CREDS_FOLDER/pal/WORKING | wc -l)
if [ $FILE_COUNT -eq 0 ]; then
	echo "/usr/bin/factory-configurator-client-example.elf did not populate the pal folder"
	exit 2
fi

mkdir -p $MBED_FOLDER
mv ./pal $MCC_CONFIG_FOLDER
