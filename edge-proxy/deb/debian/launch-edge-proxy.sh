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

# Run edge-proxy as a layer 4 (TLS) outbound proxy only. The cloud endpoint is
# reached over HTTP/2 (Envoy/NGINX), so the HTTP/1.1 reverse tunnel is disabled.

ARGS=

IDENTITY_JSON=${IDENTITY_JSON:-/var/lib/pelion/edge_gw_config/identity.json}
if [ ! -f ${IDENTITY_JSON} ]; then
    echo "ERROR: ${IDENTITY_JSON} does not exist"
    exit 1
fi

PROXY_URI=$(jq -r .edgek8sServicesAddress ${IDENTITY_JSON})

# Derive the SNI / verification hostname from the proxy URI by stripping the
# scheme, any path, and the port. The cloud is reached through an address that
# may not match its certificate, so edge-proxy needs the real hostname for SNI.
SERVER_NAME=${PROXY_URI#*://}
SERVER_NAME=${SERVER_NAME%%/*}
SERVER_NAME=${SERVER_NAME%%:*}

if [[ -n "$HTTP_PROXY" ]]; then
    ARGS="${ARGS} -extern-http-proxy-uri=$HTTP_PROXY"
fi

exec /usr/bin/edge-proxy \
    ${ARGS} \
    -proxy-uri=${PROXY_URI} \
    -server-name=${SERVER_NAME} \
    -proxy-listen=0.0.0.0:8081 \
    -use-l4-proxy=true \
    -cert-strategy=tpm \
    -cert-strategy-options=socket=/tmp/edge.sock \
    -cert-strategy-options=path=/1/pt \
    -cert-strategy-options=device-cert-name=mbed.LwM2MDeviceCert \
    -cert-strategy-options=private-key-name=mbed.LwM2MDevicePrivateKey \
    -tunnel-uri=ws://localhost:18182/connect \
    -http-tunnel-listen=localhost:18889 \
    -disable-reverse-tunnel
