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
MBED_FOLDER=/var/lib/pelion/mbed
MCC_CONFIG_FOLDER=$MBED_FOLDER/mcc_config

CREDS_FOLDER=/var/lib/creds
CREDS_CBOR_FILE=$CREDS_FOLDER/device.cbor

if [ -e ${MCC_CONFIG_FOLDER} ]; then
    echo "mcc_config exists. Success!"
    exit 0
elif [ ! -f ${CREDS_CBOR_FILE} ]; then
	echo "edge-core launch failure: please verify $CREDS_CBOR_FILE"
	exit 1
fi

cd $CREDS_FOLDER
export ENTROPYSOURCE=/dev/random
/usr/bin/factory-configurator-client-example.elf
RET_CODE=$?
if [ $RET_CODE -ne 0 ]; then
	echo "/usr/bin/factory-configurator-client-example.elf returned code $RET_CODE"
	exit $RET_CODE
fi
mkdir -p $MBED_FOLDER
mv ./pal $MCC_CONFIG_FOLDER
