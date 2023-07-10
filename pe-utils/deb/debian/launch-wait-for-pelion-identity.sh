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

IDENTITY_JSON=${IDENTITY_JSON:-/var/lib/edge/edge_gw_config/identity.json}

IDENTITY_JSON_CREATED=false
while [ ! -f ${IDENTITY_JSON} ]; do
    IDENTITY_JSON_CREATED=true
    sleep 5
    /usr/bin/generate-identity.sh 9101 /var/lib/edge/edge_gw_config
done

if ${IDENTITY_JSON_CREATED}; then
    systemctl restart edge-proxy
fi
