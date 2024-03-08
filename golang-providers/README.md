# GOlang providers

There are 2 mutually exclusive golang providers.

## golang-virtual
This package installs available version and creates symlinks.  
The version of go is specified in [build.sh](golang-virtual/deb/build.sh) and [links](golang-virtual/deb/debian/links)

## pe-golang-bin
This package creates golang package from the binary distribution.  
This is used in the [debian/buster](../build-env/target/debian/buster/packages.conf.sh), [debian/bullseye](../build-env/target/debian/bullseye/packages.conf.sh) and [ubuntu/bionic](../build-env/target/ubuntu/bionic/packages.conf.sh) build environments.  
The version of go is specified in [build.sh](pe-golang-bin/deb/build.sh)

