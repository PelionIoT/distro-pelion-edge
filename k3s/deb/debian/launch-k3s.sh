#!/bin/sh

exec /usr/bin/k3s agent \
    --config=/etc/pelion/k3s_config.yaml
