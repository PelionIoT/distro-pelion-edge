#!/bin/bash

SCRIPT_DIR=$(dirname "$0")

docker build --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) \
    -t debian10-clean "$SCRIPT_DIR"/../docker/docker-debian-10-buster
