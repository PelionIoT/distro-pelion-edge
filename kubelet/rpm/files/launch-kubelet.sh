#!/bin/sh

IDENTITY_JSON=${IDENTITY_JSON:-/var/lib/edge/edge_gw_config/identity.json}
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

exec /usr/bin/kubelet \
    --root-dir=/var/lib/edge/kubelet \
    --offline-cache-path=/var/lib/edge/kubelet/store \
    --fail-swap-on=false \
    --image-pull-progress-deadline=2m \
    --hostname-override=${DEVICE_ID} \
    --kubeconfig=/etc/edge/kubeconfig \
    --cni-bin-dir=/usr/libexec/cni \
    --cni-conf-dir=/etc/cni/net.d \
    --network-plugin=cni \
    --node-status-update-frequency=150s \
    --register-node=true \
    $NODE_IP_OPTION
