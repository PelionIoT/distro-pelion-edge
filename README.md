
  * [Build scripts for Pelion Edge](#build-scripts-for-pelion-edge)
    * [Build environment](#build-environment)
    * [Building a single package](#building-a-single-package)
    * [Building all packages](#building-all-packages)
    * [Generating tar archives](#generating-tar-archives)
    * [Build results](#build-results)
    * [APT repository](#apt-repository)

# Build scripts for Pelion Edge

The  folder `build-env`  contains helper  or common  scripts. Other  directories
contain build scripts specific for each package:
```
<package name>/deb/build.sh
metapackages/<package name>/deb/build.sh
```

The build  scripts `build.sh`  or `build-env/bin/pelion-build-all.sh`  can build
packages directly  on Ubuntu  18.04 system  or in  docker container.  The docker
container can  be launched manually, for  example as an interactive  session, or
the  scripts  will  run  docker  automatically if  the  argument  `--docker`  is
provided.

It  is recommended  to use  docker  since it  will provide  a clean  environment
without interference with local user settings  (for example, with user nodejs or
python environments).

Also, the build will need `sudo` privileges to install standard Ubuntu packages.

## Build environment

1. Scripts for creating clean build docker images:
```
$ ./build-env/bin/docker-ubuntu-bionic-create.sh # Ubuntu 18.04
```

The  above  script  creates   docker  images  `pelion-bionic-build`  with  build
essentials  and `pelion-bionic-source`  with  additional  packages required  for
generating source packages (for example git, npm, python).

To build packages for other distributions, replace `pelion-bionic` with the name
of the distribution.  For example, to build for Debian 10, use `debian-buster`.

The system is configured to use `sudo` without a password.


2. Run docker image:
```
$ ./build-env/bin/docker-run.sh <image name>
```

For example:
```
$ ./build-env/bin/docker-run.sh pelion-bionic-source
```

The script mounts the user `.ssh` directory  to share git ssh keys.  The root of
this repo is mounted to `/pelion-build`.

### Build environment for debian-10

1. Scripts for creating clean build docker images:
```
$ ./build-env/bin/docker-debian-buster-create.sh # Debian 10
```

2. Run docker image:
```
$ ./build-env/bin/docker-run.sh pelion-buster-source
```


## Building a single package

The build scripts provide help information, for example:

```
$ maestro/deb/build.sh --help
Usage: maestro/deb/build.sh [Options]

Options:
 --docker            Use docker containers.
 --source            Generate source package.
 --build             Build binary from source generated with --source option.
 --verify            Verify package conformity to the Debian policy.
 --install           Install build dependencies.
 --arch=<arch>       Set target architecture.
 --help,-h           Print this message.

 If none of '--source', '--build' or '--verify' options are specified,
 all of them are activated.

Available architectures:
  amd64
  arm64
  armhf
  armel

Default mode: maestro/deb/build.sh --arch=amd64 --source --build --verify
```

These scripts can be used to generate both source and binary packages.

It is possible to  use these scripts without the option  `--docker` if docker is
run manually by `docker-run.sh`.  The option  `--docker` will make all tasks run
in appropriate containers automatically:
* source packages will be generated in `pelion-bionic-source`
* binary packages in `pelion-bionic-build`

## Building all packages

```
$ ./build-env/bin/pelion-build-all.sh --help
Usage: pelion-build-all.sh [Options]

Options:
 --source            Generate source package.
 --build             Build binary from source generated with --source option.
 --tar               Build a tarball from Debian packages.
 --docker            Use docker containers.
 --install           Install build dependencies.
 --arch=<arch>       Set comma-separated list of target architectures.
 --help,-h           Print this message.

If none of '--source', '--build' or '--tar' options are specified,
all of them are activated.

```

This script  will run build of  each package in new  docker container installing
all build dependencies each time (with `--docker` option), for example:
```
./build-env/bin/pelion-build-all.sh --docker --arch=amd64,armhf,arm64
```

It  is  possible to  manually  run  docker and  then  build  everything in  this
container:
```
$ ./build-env/bin/docker-run.sh pelion-bionic-source
user@95a30883d637:/pelion-build$ ./build-env/bin/pelion-build-all.sh --install --arch=amd64
```

The option `--install` is required when the script is executed manually in clear
docker container, otherwise it will fail due to missing build dependencies.

## Generating tar archives

A tar archive can be created from a binary release for Debian.  One option is to
use the `pelion-build-all.sh`  script as described above.  Another  option is to
invoke `build-env/bin/deb2tar.sh` directly.

```
$ build-env/bin/deb2tar.sh --help
deb2tar.sh - converts a set of Debian packages into a portable tarball.

Usage: deb2tar.sh [-h|--help] [-a ARCH|--arch ARCH]
 -h, --help
  Display this help message.
 -a ARCH, --arch ARCH
  Set the host architecture of the tarball.
```

Before invoking `deb2tar.sh` make sure that all packages you want to be included
in the tarball are already built.

## Build results

The scripts create  or modify files only  in the `build` directory  that is also
created automatically.

There is a reusable git cache in the directory `build/downloads`.

Final Debian  packages are created in  `build/deploy/deb/bionic/main`, organized
in subdirectories per architecture:
* `binary-amd64`
* `binary-arm64`
* `binary-armhf`
* `source`

Tarballs can be found in `build/deploy/tar`, one archive per architecture.

## Installing packages

Build results can be installed onto a target system either by manually
copying the packages to a target system and installing via apt or by
making the packages available in an APT repository on a server and installing
on the target via apt. The instructions in this section show how to install
the packages manually.  See the next section for setting up an APT repository.

Copy the debian packages found in `build/deploy/deb/` to the
target system and install with `apt`.

Install all packages with the following command.
```
$ sudo apt install -y ./*.deb
```

Or, install a single package by specifying its deb file name.
```
$ sudo apt install -y ./devicedb_<version>_<arch>.deb
```

## Removing packages

To remove use command:
```
$ sudo apt remove -y <package name>
```

After remove all package, manually remove credentials and config files:
```
$ sudo rm -rf /var/lib/pelion/
```

## APT repository

Structure for APT repository server can be created in `build/deploy/deb/apt-repo`
directory by `build-env/bin/pelion-apt-repo-create.sh`. It provides help
information:

```
$ ./build-env/bin/pelion-apt-repo-create.sh --help
Usage: pelion-apt-repo-create.sh [Options]

Options:
 --key-name=<name>         Filename of secret GPG key.
 --key-[id|path]=<id|path> Use key id of existing GPG key or path where private key is placed.
 --install                 Installs the necessary tools to create structure for apt repository.
 --help,-h                 Print this message.

```

An APT repository and its contents have to  be signed with a GPG key.  There are
two ways to pass such a key to the  script: using an id of a key stored in one's
GPG keyring or a filesystem path to a secret key. The default is to use the file
`build/deploy/deb/gpg/Pelion_GPG_key_private.gpg`.

### GPG key pair generation

To generate a key pair one can use `build-env/bin/pelion-gpg-key-generate.sh`:
```
$ ./build-env/bin/pelion-gpg-key-generate.sh --help
Usage: pelion-gpg-key-generate.sh --key-email=<email> [Options]

Options:
 --key-name=<name>             Set name of GPG key and filename of public (<name>_public.gpg)
                               and private (<name>_private.gpg) keys.
 --key-email=<email>           Set email of GPG key.
 --key-path=<path>             Set path where public and private keys will be placed.
 --install                     Installs the necessary tools to generate the gpg key pair.
 --help,-h                     Print this message.

```

The `--key-email`  flag is required  (it's the email part  of a key's  id).  The
generated public  and private  keys will  be placed  into `build/deb/deploy/gpg`
directory by default, but this can be changed using the `--key-path` option.

### APT repository usage

In order to get access to an apt  repository add a line of the following form in
`/etc/apt/sources.list`:
```
deb [arch=amd64] http://<ip address> bionic main
```

Then import the GPG key the repository was signed with:
```
wget -q -O - http://<ip address>/key.gpg | sudo apt-key add -
```
