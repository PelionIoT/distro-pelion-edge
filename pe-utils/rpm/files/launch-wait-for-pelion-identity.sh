#!/bin/bash

while :
do
    /usr/lib/pelion/generate-identity.sh "$@" && break
    sleep 5
done
