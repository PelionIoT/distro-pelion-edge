# Table of contents
* [Build scripts for Pelion Edge](#build-scripts-for-pelion-edge)
  * [Quickstart](#quickstart)
  * [Selecting target distribution with `--docker` switch](#selecting-target-distribution-with---docker-switch)
  *  [Preparing host to compile packages](#preparing-host-to-compile-packages)
    - [System requirements](#system-requirements)
    - [Red Hat Enterprise Linux (RHEL) subscription](#red-hat-enterprise-linux-rhel-subscription)
  * [Build environment](#build-environment)
    - [*Container* `-c` and *image* `-r` flags](#container--c-and-image--r-flags)
  * [Building a single package](#building-a-single-package)
    - [Build single package for Debian and Ubuntu](#build-single-package-for-debian-and-ubuntu)
    - [Build single package for Red Hat and Centos](#build-single-package-for-red-hat-and-centos)
  * [Building all packages](#building-all-packages)
  * [Generating tar archives](#generating-tar-archives)
  * [Build results](#build-results)
  * [Preparing Red Hat system before installation](#preparing-red-hat-system-before-installation)
    - [RHEL Repositories](#rhel-repositories)
    - [Docker](#docker)
    - [SELinux](#selinux)
  * [Installing packages](#installing-packages)
    - [Installing on Debian or Ubuntu](#installing-on-debian-or-ubuntu)
    - [Installing on Red Hat or Centos](#installing-on-red-hat-or-centos)
  * [Removing packages](#removing-packages)
  * [APT repository](#apt-repository)
    - [GPG key pair generation](#gpg-key-pair-generation)
    - [APT repository usage](#apt-repository-usage)
  * [FOTA](#fota)

# Build scripts for Pelion Edge

The  folder `build-env`  contains helper  or common  scripts. Other  directories
contain build scripts specific for each package, for Debian-based distributions:
```
<package name>/deb/build.sh
metapackages/<package name>/deb/build.sh
```
and for *Red Hat*-based distributions:
```
<package name>/rpm/build.sh
```

The build scripts `build.sh`  or `build-env/bin/build-all.sh` can build packages
directly on supported  systems or in docker container. The  docker container can
be launched manually, for example as an interactive session, or the scripts will
run docker automatically if the argument `--docker` is provided.

It  is recommended  to use  docker  since it  will provide  a clean  environment
without interference with local user settings  (for example, with user nodejs or
python environments) and does not require setting up local packages repository.

Also, the build will need `sudo` privileges to install standard Ubuntu packages.

## Quickstart
First make sure your system is configured correctly (see [requirements](#requirements))

Here's how to quickly build Pelion Edge Packages for *Ubuntu Focal* amd64.

1. Prepare `mbed_cloud_dev_credentials.c` and `update_default_resources.c`
files:
```bash
# copy your mbed_cloud_dev_credentials.c file in place so that the edge devmode package will build with your dev credentials
cp ~/Downloads/mbed_cloud_dev_credentials.c .
# use manifest tool to create an update_default_resources.c so that you'll be ready to perform an over-the-air-update
# copy the generated update_default_resources.c into place
cp /path/to/update_default_resources.c .
```

2. Run build scripts:
```bash
# build all the Ubuntu 20 packages for amd64 using docker container
./build-env/bin/docker-run-env.sh focal ./build-env/bin/build-all.sh --deps --install --build --source --arch=amd64
# deb packages will be available in ./build/deploy/deb/focal/main/


# then if you'd like to rebuild an individual package (ex: mbed-edge-core-devmode)
./build-env/bin/docker-run-env.sh focal ./mbed-edge-core-devmode/deb/build.sh --install --build --source --arch=amd64
```

Alternative way to run build scripts:

```bash
# build all the Ubuntu 20 packages for amd64 using docker container
./build-env/bin/build-all.sh --docker=focal --deps --install --build --source --arch=amd64
# deb packages will be available in ./build/deploy/deb/focal/main/


# then if you'd like to rebuild an individual package (ex: mbed-edge-core-devmode)
./mbed-edge-core-devmode/deb/build.sh --docker=focal --install --build --source --arch=amd64
```


## Selecting target distribution with `--docker` switch

The  `--docker` switch  (or short  `-d`) is  used to  select build  environment.
Environment  configurations   are  stored  in  `./build-env/target/`.   To  list
available environments run:
```bash
./build-env/bin/build-all.sh -l env
```

The `-d`  accepts also  partial environments  names (`-d  rh`, `-d  rhel/8`, `-d
rhel-8`,  `-d  rhel`  -  all  are  valid).  When  name  matches  more  than  one
environment, script will print error:
```bash
$ ./build-env/bin/build-all.sh -d 8
Unable to load environment: ambiguous environment name, matches:
centos/8 rhel/8

```

## Preparing host to compile packages
### System requirements
The  `build-all.sh`  script  requires   docker,  bash  4.2+,  gnu-findutils  and
gnu-getopt.

To  build arm64  packages  for *Red  Hat*  or *Centos*  `qemu`  is required  and
qemu-docker  integration  because  *Red  Hat*/*Centos* does  not  support  cross
compiling.

To enable qemu-docker integration on Linux `binfmt` has to be enabled using this
image before using arm64 compilation:
```bash
docker run --rm --privileged docker/binfmt:a7996909642ee92942dcd6cff44b9b95f08dad64
```

The `binfmt` has to be executed once after every reboot.

Build on MacOS is not tested.

### Red Hat Enterprise Linux (RHEL) subscription
RHEL  images  does  not  include  subscription  credentials.  `RH_USERNAME`  and
`RH_PASSWORD` variables  with your  Red Hat  subscription credentials  should be
exported as environment variables before running build scripts:

```bash
export RH_USERNAME="Your Red Hat username"
export RH_PASSWORD="Your Red Hat password"
```

Variables will be used to create docker image. If any of the variables would not
be set, scripts  will interactively ask for them. Credentials  will be stored in
docker image. Note that for free development subscription only 16 systems can be
registered (registered  systems can be  removed on RHEL  subscription management
page).

To create Red Hat account visit: https://www.redhat.com/wapps/ugc/register.html


## Build environment

To access  build environment console `docker-run-env.sh`  script was introduced.
The script accepts options until first positional argument (which is environment
name).

Example usage:
```bash
# run new rhel/8 image for host arch:
./build-env/bin/docker-run-env.sh rhel

# run centos container (exec in existing)
./build-env/bin/docker-run-env.sh -c centos

# run 'ls' in centos container
./build-env/bin/docker-run-env.sh -c centos ls

# run fresh container (and allow later executing in it)
./build-env/bin/docker-run-env.sh -c clean centos ls

# recreate docker image and container and run shell in new container
./build-env/bin/docker-run-env.sh -r -c clean centos

# run new arm64 container
./build-env/bin/docker-run-env.sh -c=clean -a arm64 centos
```

The  above script  also creates  docker images  with build  essentials and  with
additional packages  required for generating  source packages (for  example git,
npm, python) depending on selected environment.

To  add prefix  to docker  images and  containers export  `PELION_DOCKER_PREFIX`
variable in your shell with your prefix:
```
export PELION_DOCKER_PREFIX=${USER}-
```

The system in docker image is configured to use `sudo` without a password.

The root of this repo is mounted to `/pelion-build`.

To get list of all supported target distributions, run:
```bash
./build-env/bin/build-all.sh -l env
```

It is  not required to  specify full  name of environment  (eg. `ubuntu/focal`).
Partial, unique match would also work (like in quickstart example: `focal`).

### *Container* `-c` and *image* `-r` flags
The `-c` flag  enables reusing of docker *containers* -  only one container will
be used.  This speeds up  whole build when `--docker`  (or `-d`) switch  is used
especially for arm64 on amd64 build. If container gets corrupted for some reason
using `-c=clean` will create fresh container before build.

When `build-all.sh` is run:
- without `-c`  - new container is  created on each element  (each package build
and source stage). Container is removed after each element is done:
	```
	# create and run temporary container
	[docker run --rm] pe-nodejs source
	# container is automatically removed
	# create and run temporary container
	[docker run --rm] fluent-bit source
	# container is automatically removed
	...
	```

- with `-c`  script checks if there  is a container, creates it  if missing, and
uses it for each element:
	```
	[check if container exists => create if missing]
	[if stopped => docker start]
	[docker exec] pe-nodejs source
	[docker exec] fluent-bit source
	...
	[docker exec] pe-nodejs build
	```

- with  `-c=clean` removes existing container  and creates new one  before first
use in script:
	```
	# clean part
	[docker container remove]
	# create new container
	[docker container create]
	[docker start]
	[docker exec] pe-nodejs source
	[docker exec] fluent-bit source
	...
	[docker exec] pe-nodejs build
	...
	```

When `-c`  flag is used  in `build-all.sh`, the  container can be  accessed with
`docker-run-env.sh -c` command.  It can be run multiple times  so multiple shell
sessions can be created  in one container. It also allow  to reboot host machine
and attach to previously used session.

As script now  automatically creates required images, `-r`  flag was introduced.
The `-r` flag forces script to recreate docker *images*.

## Building a single package

Dependency packages must be built prior to building a single package.
```bash
./build-env/bin/build-all.sh --deps --install --docker=<dist>
```
or
```bash
./build-env/bin/docker-run-env.sh <dist> ./build-env/bin/build-all.sh --deps --install
```

### Build single package for Debian and Ubuntu
The build scripts provide help information, for example:

```
$ maestro/deb/build.sh --help
Usage: maestro/deb/build.sh [Options]

Options:
 --docker=<dist>     Use docker containers (dist can be focal, bionic, buster...).
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

Default mode: maestro/deb/build.sh --arch=amd64 --source --build --verify
```

These scripts can be used to generate both source and binary packages.

It is possible to  use these scripts without the option  `--docker` if docker is
run manually by  `docker-run-env.sh`. The option `--docker` will  make all tasks
run in appropriate containers automatically (using source of build images):

### Build single package for Red Hat and Centos
The build scripts for RPM-based distributions are similar to Debian's:

```
$ ./maestro/rpm/build.sh --help
build.sh - builds maestro RPM package

Usage: build.sh [-h|--help] [--install]
 -h, --help                 display this help message.
 -i, --install              install dependencies
 -b, --build                build package
 -s, --source               prepare sources
 -d, --docker=<name>        use docker container to build RPM
 -a, --arch=<name>          build for selected architecture
 -c, --container=[opts]     reuse container; opts can be (comma separated):
                            - clean - create new container before first use
 -r, --recreate             forcibly recreate docker images (implies -c=clean)
 -o, --deploy=<path>        set target directory for RPMs

```

Additionally  these  scripts supports  Docker  image  creation when  needed  and
container re-usage.

## Building all packages

```
$ ./build-env/bin/build-all.sh --help
build-all.sh - build all packages:

USAGE: 
-a, --arch=<name>       run build for <name> architecture
-d, --docker=<name>     run build in docker (name=docker environment)
-h, --help              print this help text
-i, --install           install dependencies
-e, --print-env=[what]  print environment setup: packages, meta, deps
                        (deps packages)
-l, --print-list        print list: env (list of available environments)
-c, --container=[opts]  use one container per kind instead of container
                        per package; opts can be (comma separated):
                        - clean - create new container before first use
-r, --recreate          forcibly recreate docker images (implies -c=clean)

Build elements:
-b, --build             run build stage
-s, --source            run source stage
-t, --tar               run tarball creation stage
-p, --deps              run dependency compilation stage

When no -b, -s, -t or -p are set, all are enabled. Setting one of them will
disable unset parameters (eg. setting -b -s will run only source and build
stage).

If --docker is set, build process will run in new container. By adding --container
scripts will use one container to build all packages (instead of container
per package)
```

This script  will run build of  each package in new  docker container installing
all build dependencies each time (with `--docker` option), for example:
```
./build-env/bin/build-all.sh --docker=focal --arch=amd64,armhf,arm64
```

By adding `--container`  option, one container will be used  if possible. Adding
`--container clean` will remove existing container before build.

It  is  possible to  manually  run  docker and  then  build  everything in  this
container:
```
$ ./build-env/bin/docker-run-env.sh bionic
user@95a30883d637:/pelion-build$ ./build-env/bin/build-all.sh --install --arch=amd64
```

When  build  requires  different  architecture (when  cross-compilation  is  not
available,  like for  *Red  Hat*)  `--arch=<architecture>` has  to  be added  to
`docker-run-env.sh` before specifying target environment:
```bash
./build-env/bin/docker-run-env.sh --arch arm64 rhel
```

The option  `--install` is required  when the script  is executed in  new docker
container, otherwise it will fail due to missing build dependencies.

To  provide  build  dependency  use  `--deps` switch.  This  will  create  build
dependencies and  put into local repository.  This is enabled by  default if not
build/source/tar is set.

## Generating tar archives

A tar archive can  be created from a binary release for  Debian and Ubuntu only.
One  option is  to use  the `build-all.sh`  script as  described above.  Another
option is to invoke
`build-env/bin/deb2tar.sh` directly.

```
$ build-env/bin/deb2tar.sh --help
deb2tar.sh - converts a set of Debian packages into a portable tarball.

Usage: deb2tar.sh [-h|--help] [-a ARCH|--arch ARCH]
 -h, --help
  Display this help message.
 -a ARCH, --arch ARCH		Set the host architecture of the tarball.
 -d DISTRO, --distro DISTRO Set Linux distro (eg. focal, buster...)
```

Before invoking `deb2tar.sh` make sure that all packages you want to be included
in the tarball are already built.

## Build results

The scripts create  or modify files only  in the `build` directory  that is also
created automatically.

There is a reusable git cache in the directory `build/downloads`.

Final Debian packages are created in `build/deploy/deb/<DISTRO>/main`, organized
in subdirectories per architecture:
* `binary-amd64`
* `binary-arm64`
* `binary-armhf`
* `source`

Tarballs can be found in `build/deploy/tar`, one archive per architecture.

*Red Hat* and *Centos* packages are created in `build/deploy/rpm/<DISTRO>`:
* source packages are on top of this directory
* `noarch`, `x86_64` and `aarch64` directories contains final packages

## Preparing Red Hat system before installation
Here are notes for installation compiled packages on target system.

### RHEL Repositories
CodeReady and EPEL have to be  enabled before installation EPEL is required only
for mbed-edge-example package.

```bash
sudo subscription-manager repos --enable codeready-builder-for-rhel-8-x86_64-rpms
sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
```

### Docker
RHEL 8 does not support Docker, to  use kubelet it is required to install Docker
from  external repository.  This is  required only  to run  built binaries  (not
required to do the actual build). To add the repository, run:

```bash
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

### SELinux
SELinux is not  currently supported: `pelion-relay-term` service  will be killed
when SELinux is enabled.

SELinux  has to  be  disabled, set  to  permissive or  `node`  binary should  be
excluded. More details about SELinux and its configuration here:
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/using_selinux/index

## Installing packages

Build results can  be installed onto a target system  either by manually copying
the packages  to a  target system and  installing via apt/yum  or by  making the
packages available  in an package repository  on a server and  installing on the
target via  apt/yum. The instructions  in this section  show how to  install the
packages  manually. See  the  next  section for  setting  up  an APT  repository
(Debian/Ubuntu only).

### Installing on Debian or Ubuntu

Copy  the debian  packages found  in `build/deploy/deb/<DISTRO>`  to the  target
system and install with `apt`.

Install all packages with the following command.
```bash
$ sudo apt install -y ./*.deb
```

Or, install a single package by specifying its deb file name.
```bash
$ sudo apt install -y ./fluent-bit_<version>_<arch>.deb
```

### Installing on Red Hat or Centos
1.  Before installing  packages make  sure  that you  have subscription  enabled
and   EPEL,  CodeReady   and  Docker   repositories  are   enabled  (see   [RHEL
repositories](#rhel-Repositories) and [Docker](#docker)).

2. Copy      content       of       `build/deploy/rpm/<distro>/<arch>`       and
`build/deploy/rpm/<distro>/noarch/` to target system  (where `<arch>` is `amd64`
or `arm64` and `<distro>` is `rhel8` or `centos8`).

3. To  install use  `yum` command, for  example if all  packages are  in current
directory run:
```bash
sudo yum install *.rpm
```

Please  note  that  `mbed-edge-core`   and  `mbed-edge-core-devmode`  cannot  be
installed simultaneously.

4. Enable `systemd` services. After installation there are following services:
```
edge-core.service
edge-proxy.service
kubelet.service
maestro.service
mbed-fcc.service
pelion-relay-term.service
wait-for-pelion-identity.service
```

To enable all services, run:
```bash
sudo systemctl enable edge-core.service edge-proxy.service kubelet.service maestro.service mbed-fcc.service pelion-relay-term.service wait-for-pelion-identity.service
```

Dependent     services      are     enabled     implicitly.      For     example
`wait-for-pelion-identity.service`   is   enabled  when   `maestro.service`   is
enabled; `edge-core.service` is  enabled when `wait-for-pelion-identity.service`
is    enabled     so    enabling    `maestro.service`    will     also    enable
`wait-for-pelion-identity.service` and `edge-core.service`.


## Removing packages
List  of packages  can  be  printed with  following  command  (here example  for
packages in *Ubuntu Focal*):
```bash
$ ./build-env/bin/build-all.sh -d focal -l packages
```

To remove package on Debian/Ubuntu use command:
```bash
$ sudo apt remove -y <package name> --autoremove --purge
```

or on *Red Hat*/*Centos*:

```bash
$ sudo yum remove -y <package name>
```

After removing all packages, manually remove credentials and config files:
```bash
$ sudo rm -rf /var/lib/pelion/
$ sudo rm -rf /etc/pelion/
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

## FOTA

Firmware Over-The-Air(FOTA) behavior is currently undefined

## Known Issues

### iptables versioning

There is a bug in iptables versions 1.8.0->1.8.2 that causes kubelet to create duplicate firewall rules.

For more information, see the following known issues:
* https://github.com/kubernetes/kubernetes/issues/71305
* https://github.com/kubernetes/kubernetes/issues/76431

Some suggested workarounds include:
* Running the following command on the host: `update-alternatives --set iptables /usr/sbin/iptables-legacy`
* Upgrade iptable to version 1.8.3+
