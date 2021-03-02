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

ARGS=

IDENTITY_JSON=${IDENTITY_JSON:-/var/lib/pelion/edge_gw_config/identity.json}
if [ ! -f ${IDENTITY_JSON} ]; then
    echo "WARNING: ${IDENTITY_JSON} does not exist"
else
    DEVICE_ID=$(jq -r .deviceID ${IDENTITY_JSON})
    if ! grep -q "$DEVICE_ID" /etc/hosts; then
        echo "127.0.0.1 $DEVICE_ID" >> /etc/hosts
    fi

    EDGE_K8S_ADDRESS=$(jq -r .edgek8sServicesAddress ${IDENTITY_JSON})
    ARGS="${ARGS} -proxy-uri=${EDGE_K8S_ADDRESS}"

    GATEWAYS_ADDRESS=$(jq -r .gatewayServicesAddress ${IDENTITY_JSON})
    ARGS="${ARGS} -forwarding-addresses={\"gateways.local\":\"${GATEWAYS_ADDRESS#"https://"}\"}"
fi

EDGE_PROXY_URI_RELATIVE_PATH=$(jq -r .edge_proxy_uri_relative_path /etc/pelion/edge-proxy.conf.json)

if ! grep -q "gateways.local" /etc/hosts; then
    echo "127.0.0.1 gateways.local" >> /etc/hosts
fi

if [[ -n "$HTTP_PROXY" ]]; then
    ARGS="${ARGS} -extern-http-proxy-uri=$HTTP_PROXY"
fi

exec /usr/bin/edge-proxy \
    ${ARGS} \
    -tunnel-uri=ws://gateways.local$EDGE_PROXY_URI_RELATIVE_PATH \
    -cert-strategy=tpm \
    -cert-strategy-options=socket=/tmp/edge.sock \
    -cert-strategy-options=path=/1/pt \
    -cert-strategy-options=device-cert-name=mbed.LwM2MDeviceCert \
    -cert-strategy-options=private-key-name=mbed.LwM2MDevicePrivateKey
