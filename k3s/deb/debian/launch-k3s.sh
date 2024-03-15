#!/bin/sh

exec /usr/bin/k3s agent \
    --config=/etc/edge/k3s_config.yaml
