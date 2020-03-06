# Build scripts for Pelion Edge

The folder `build-env` contains helper or common scripts. Other directories
contain build scripts specific for each package:
```
<package name>/deb/build.sh
```

The build scripts `build.sh` or `build-env/bin/pelion-build-all.sh` can build packages
directly on Ubuntu 18.04 system or in docker container. The docker container can be launched
manually, for example as an interactive session, or the scripts will run docker automatically
if the argument `--docker` is provided.

It is recommended to use docker, since it will provide clean environment without
interference with local user setting (for example, with user ~/.npmrc or user python
environment).
Also the build will need `sudo` privileges to install standard Ubuntu packages.

## Build environment

1. Scripts for creating clean build docker images:
```
$ ./build-env/bin/bin/docker-ubuntu-bionic-create.sh # Ubuntu 18.04
```

The above script creates docker images `pelion-bionic-build` with build
essentials and `pelion-bionic-source` with additional packages required for
generating source packages (for example git, npm, python)

The system is configured to use `sudo` without a password.


2. Run docker image:
```
$ ./build-env/bin/docker-run.sh <image name>
```

For example
```
$ ./build-env/bin/docker-run.sh pelion-bionic-source
```

The script mounts the user `.ssh` directory to share git ssh keys.

The root of this repo is mounted to `/pelion-build`.

## Building single package

The build scripts provide help information, for example

```
$ maestro/deb/build.sh --help
Usage: maestro/deb/build.sh [Options]

Options:
 --docker            Use docker containers.
 --source            Generate source package.
 --build             Build binary from source generated with --source option.
 --install           Install build dependencies.
 --arch=<arch>       Set target architecture.
 --help,-h           Print this message.

If neither '--source' nor '--build' option is specified both are activated.
```

It is possible to call the scripts just to generate standard Debian source package
or to build only if the source was generated before.

It is possible to use this script without the option `--docker` if the docker is
run manually by `docker-run.sh`.
The option `--docker` will trigger automatically each job in proper container:
 * source generation in `pelion-bionic-source`
 * build in `pelion-bionic-build`

## Building all packages

```
$ ./build-env/bin/pelion-build-all.sh --help
Usage: pelion-build-all.sh [Options]

Options:
 --source            Generate source package.
 --build             Build binary from source generated with --source option.
 --docker            Use docker containers.
 --install           Install build dependencies.
 --arch=<arch>       Set comma-separated list of target architectures.
 --help,-h           Print this message.

If neither '--source' nor '--build' option is specified both are activated.
```

This script will run build of each package in new docker container installing
all build dependencies each time (with `--docker` option), for example
```
./build-env/bin/pelion-build-all.sh --docker --arch=amd64,armhf,arm64
```

It is possible to manually run docker and then build everything in
this container:
```
$ ./build-env/bin/docker-run.sh pelion-bionic-source
user@95a30883d637:/pelion-build$ ./build-env/bin/pelion-build-all.sh --install --arch=amd64
```
The option `--install` is required when the script is executed manually in clear
docker container, otherwise it will fail due to missing build dependencies.

## Build results

The scripts create or modify files only in the `build` directory that is also created automatically.

There is reusable git cache in the directory `build/downloads`.

Final Debian packages are created in `build/deploy/deb/bionic/main` organized in
subdirectories per architecture:
* `binary-amd64`
* `binary-arm64`
* `binary-armhf`
* `source`
