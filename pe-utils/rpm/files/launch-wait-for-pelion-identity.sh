#!/bin/bash

while :
do
    /usr/lib/edge/generate-identity.sh "$@" && break
    sleep 5
done
