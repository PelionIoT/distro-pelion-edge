# RHEL 8 support

## Quickstart
Make sure your system is configured correctly (see [requirements](#requirements))

### Build all packages
1. To build all packages for amd64 run:
```bash
./build-env/bin/build-all.sh -i -d rhel -c
```
2. Packages will be placed in `./build/deploy/rpm/rhel8/`

You can add `--arch arm64` argument to `build-all.sh` if you want to build only arm64 packages, or `--arch amd64,arm64` to build packages for both architectures.

### Build individual packages
1. Build common dependencies:

```bash
./build-env/bin/build-all.sh -i --deps -d rhel -c
```
2. Build individual package, eg.:
```bash
./maestro/rpm/build.sh -i -c
```

### Docker console
To access build environment console `docker-run-env.sh` script was introduced. The script accepts options until first positional argument (which is environment name).

Example usage (`./build-env/bin/` path prefix omitted):

1. run new rhel/8 image for host arch:
```bash
 docker-run-env.sh rhel
```
2. run centos container (attach to existing)
```bash
 docker-run-env.sh -c centos
```
3. run 'ls' in centos container
```bash
 docker-run-env.sh -c centos ls
```
4. run fresh container (and allow later attaching to it)
```bash
 docker-run-env.sh -c clean centos ls
```
5. recreate docker image and container and run shell in new container
```bash
 docker-run-env.sh -r -c clean centos
```
6. run new arm64 container
```bash
 docker-run-env.sh -c=clean -a arm64 centos
```

### The `--docker` switch
The `--docker` switch (or short `-d`) is used to select build environment. Environment configurations are stored in `./build-env/target/`. To list available environments run:
```bash
./build-env/bin/build-all.sh -l env
```

The `-d` accepts also partial environments names (`-d rh`, `-d rhel/8`, `-d rhel-8`, `-d rhel` - all are valid). When name matches more than one environment, script will print error:
```bash
$ ./build-env/bin/build-all.sh -d 8
Unable to load environment: ambiguous environment name, matches:
centos/8 rhel/8

```

### Note regarding `-c` flag and `-r`
The `-c` flag enables reusing of docker *containers* - only one container will be used. This speeds up whole build when `--docker` (or `-d`) switch is used especially for arm64 on amd64 build. If container gets corrupted for some reason using `-c=clean` will create fresh container before build.

As script now automatically creates required images, `-r` flag was introduced. The `-r` flag forces script to recreate docker *images*.

## Compiling packages notes
### System requirements
The `build-all.sh` Script requires bash 4.2+ and gnu-getopt.
To build arm64 packages qemu is required and qemu-docker integration.

On Linux binfmt has to be enabled using this image before using arm64 compilation:
```bash
docker run --rm --privileged docker/binfmt:a7996909642ee92942dcd6cff44b9b95f08dad64
```

`binfmt` has to be executed once after every reboot

MacOS support is not tested.

### RHEL subscription
RHEL images does not include subscription credentials.  `RH_USERNAME` and `RH_PASSWORD` variables with your Red Hat subscription credentials should be exported as environment variables before running build scripts:

```bash
export RH_USERNAME="Your Red Hat username"
export RH_PASSWORD="Your Red Hat password"
```

Variables will be used to create docker image. If any of the variables would not be set, scripts will interactively ask for them. Credentials will be stored in docker image. Note that for free development subscription only 16 systems can be registered (registered systems can be removed on RHEL subscription management page).

To create Red Hat account visit: https://www.redhat.com/wapps/ugc/register.html

## Target installation requirements
Here are notes for installation compiled packages on target system.

### RHEL Repositories
CodeReady and EPEL have to be enabled before installation
EPEL is required only for mbed-edge-example package.

```bash
sudo subscription-manager repos --enable codeready-builder-for-rhel-8-x86_64-rpms
sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
```

### Docker
RHEL 8 does not support Docker, to use kubelet it is required to install Docker from external repository.  This is required only to run built binaries (not required to do the actual build).  To add the repository, run:

```bash
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

### SELinux
SELinux is not currently supported: `pelion-relay-term`  service will be killed when SELinux is enabled.
SELinux has to be disabled, set to permissive or `node` binary should be excluded. More details about SELinux and its configuration here: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/using_selinux/index

## Target package installation
1. Before installing packages make sure that you have subscription enabled and EPEL, CodeReady and Docker repositories are enabled (see [RHEL repositories](#rhel-Repositories) and [Docker](#docker)).
2. Copy content of `build/deploy/rpm/<distro>/<arch>` and `build/deploy/rpm/<distro>/noarch/` to target system (where `<arch>` is `amd64` or `arm64` and `<distro>` is `rhel8` or `centos8`).

3. To install use `yum` command, for example if all packages are in current directory run:
```bash
sudo yum install *.rpm
```
Please note that `mbed-edge-core` and `mbed-edge-core-devmode` cannot be installed simultaneously.

## Development notes
Each environment configuration file can/should implement below listed callbacks.

`ARCH` variable is exported before calling `run_*` callbacks.

### Environment callbacks
#### `env_load`
Is called when environment is loaded (once per session)

#### `env_load_post`
Is called at the end of loading environment (after internal setup based on changes made in `env_load`)

#### `env_load_docker`
Is called before running docker on host machine to prepare docker execution (eg. create directories for volume mounts)

#### `env_arch_supported`
arg1: architecture name `string`

Return `true` if `arg1` architecture is supported in environment.

#### `env_match_current`
Returns true if current execution environment matches loaded one (used for environment detection when no `--docker` switch was set)

#### `docker_image_create`
arg1: `build` or `source`, can be ignored when build does not use split images

Create docker images. Usually calls `docker_build_image PATH/TO/Dockerfile`.

#### `docker_image_name`
arg1: `build` or `source`, can be ignored when build does not use split images

Returns image name for current environment.

#### `run_source`
arg1: package name

Function will be called when 'source' build is requested. As arg1 package name is set (eg. pe-nodejs).

#### `run_build`
arg1: package name

Same as for `run_source`, but for package 'build' stage.

#### `run_source_deps`
arg1: package name

Optional, `run_source` is set as default. Same as for 'source', but called for source build of dependency package.

#### `run_build_deps`
arg1: package name

Optional, `run_build` is set as default. Same as for `run_source_deps` but for 'build' stage.

#### `run_build_metapackage`
arg1: package name

Build metapackage function. It should run proper script to build requested package

#### `run_tar_build`
Run tar archive build

#### `run_deploy_deps`
arg1: package name

Function is called when arg1 package should be deployed to internal package repository.

#### `path_package_script`
arg1: package name

Print path to build.sh script relative to repository root.

#### `docker_pre_run`
Function which will be called just before running docker create or docker run commands. Used to set proper `PLATFORM_ARCH`.

### Environment variables
#### `PACKAGES=( )`, `DEPENDS=( )`, `METAPACKAGES=( )` arrays
Arrays to list packages supported in current environment. `PACKAGES` array is mandatory.

#### `opt_*_arch` arrays

The `opt_*_arch` variables are set as array from value passed in `--arch` param. All has initially same value as `arg_arch` variable. `env_load` can modify them to enable different architectures for different stages - for example on cross-compiled environments only host architecture is needed for dependencies, not all listed in `--arch`. If `--arch` is not set host architecture is used.

- `opt_build_arch` - array of architecture names used for build and source stages for regular packages.
- `opt_meta_arch` - arrays of architecture names used to build metapackages. Usually host architecture should be used.
- `opt_deps_arch` - array of architecture names for dependency build. On cross-compilation enabled environments host arch should be set. On emulated - target architecture.


### Helper functions

#### `docker_image_run`
arg1: `build` or `source`
arg2-N: run command and its arguments

Run command in temporary docker container.

#### `docker_build_image`
arg1: Dockerfile
arg2: image type: `build` or `source` (to resolve image name)

ENV:
 - `CTX_PATH` - build context root directory, default: Dockerfile directory
 - `PELION_DOCKER_PREFIX` - prefix to image name (passed as PREFIX arg to the build instance)
 - `DOCKER_BUILD_ARGS` - list additional build arguments (will prepend `--build-arg` on each element)
 - `PLATFORM_ARCH` - `--platform=$PLATFORM_ARCH` passed to docker if set (optional, default: no `--platform` arg)

NOTE: --pull flag required to workaround multiarch issue

Dockerfile arguments provided by this function (`--build-arg`):
- `USER_ID`
- `GROUP_ID`
- `PREFIX`

Build docker images using Dockerfile

#### `run_command_build` and `run_command_source`
arg1-N: command to run with its arguments

Run command in docker container (temporary or reused) or natively if `--docker` is not set.

If docker image is missing it will be created.
