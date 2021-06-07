#!/bin/bash

IDENTITY_JSON=${IDENTITY_JSON:-/var/lib/pelion/edge_gw_config/identity.json}
DEVICE_ID=$(jq -r .deviceID ${IDENTITY_JSON})
if [ $? -ne 0 ]; then
    echo "Unable to extract device ID from identity.json"
    exit 1
fi

/usr/bin/launch-edgenet.sh
if [ $? -ne 0 ]; then
    echo "Unable to create edgenet docker network"
    exit 2
fi

# Get the IP address of the interface with Internet access
IP_ADDR=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+')

if [ -n $IP_ADDR ]; then
    NODE_IP_OPTION="--node-ip=$IP_ADDR"
else
    NODE_IP_OPTION=""
fi

FIRST_BROKEN_VERSION='iptables v1.8.0'
FIRST_WORKING_VERSION='iptables v1.8.3'
IPTVERSION=$(iptables --version)

# check if iptables is between the min and max version if so we have a bugged iptables
if ! [ "$(echo -e ${FIRST_BROKEN_VERSION}\\n${IPTVERSION} | sort -V | head -1)" != "${FIRST_BROKEN_VERSION}" -o \
       "$(echo -e ${FIRST_WORKING_VERSION}\\n${IPTVERSION} | sort -V | tail -1)" != "${FIRST_WORKING_VERSION}" ]; then
    # if the iptables == iptables-legacy versions we are in good shape
    # we don't work correctly on debian with iptables-nft
    if [[ "${IPTVERSION}" != "$(iptables-legacy --version)" ]]; then
        echo 'WARNING starting kublet:'
        echo 'There is a bug in iptables versions 1.8.0->1.8.2 that causes kubelet to create duplicate firewall rules.'
        echo
        echo 'For more information, see the following known issues:'
        echo '  https://github.com/kubernetes/kubernetes/issues/71305'
        echo '  https://github.com/kubernetes/kubernetes/issues/76431'
        echo
        echo 'Some suggested workarounds include:'
        echo '  Run the following command on the host: update-alternatives --set iptables /usr/sbin/iptables-legacy'
        echo '  Upgrade iptables to version 1.8.3+'
    fi
fi 

exec /usr/bin/kubelet \
    --root-dir=/var/lib/pelion/kubelet \
    --offline-cache-path=/var/lib/pelion/kubelet/store \
    --fail-swap-on=false \
    --image-pull-progress-deadline=2m \
    --hostname-override=${DEVICE_ID} \
    --kubeconfig=/etc/pelion/kubeconfig \
    --cni-bin-dir=/usr/lib/cni \
    --cni-conf-dir=/etc/cni/net.d \
    --network-plugin=cni \
    --node-status-update-frequency=150s \
    --register-node=true \
    $NODE_IP_OPTION