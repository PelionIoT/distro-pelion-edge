# Development notes for `build-all` scripts library
Scripts are located in `build-env/inc/build-all/`. 
Target definitions are located in `build-env/target/`.
Each environment configuration file can/should implement below listed callbacks.

Directory is  identified as  environment (target)  if it  has `packages.conf.sh`
file inside and directory is not hidden.

`ARCH` variable is exported before calling `run_*` callbacks.

## Environment callbacks
### `env_load`
Is called when environment is loaded (once per session)

### `env_load_post`
Is called at the end of loading environment (after internal setup based on changes made in `env_load`)

### `env_load_docker`
Is called before running docker on host machine to prepare docker execution (eg. create directories for volume mounts)

### `env_arch_supported`
arg1: architecture name `string`

Return `true` if `arg1` architecture is supported in environment.

### `env_match_current`
Returns true if current execution environment matches loaded one (used for environment detection when no `--docker` switch was set)

### `docker_image_create`
arg1: `build` or `source`, can be ignored when build does not use split images

Create docker images. Usually calls `docker_build_image PATH/TO/Dockerfile`.

### `docker_image_name`
arg1: `build` or `source`, can be ignored when build does not use split images

Returns image name for current environment.

### `run_source`
arg1: package name

Function will be called when 'source' build is requested. As arg1 package name is set (eg. pe-nodejs).

### `run_build`
arg1: package name

Same as for `run_source`, but for package 'build' stage.

### `run_source_deps`
arg1: package name

Optional, `run_source` is set as default. Same as for 'source', but called for source build of dependency package.

### `run_build_deps`
arg1: package name

Optional, `run_build` is set as default. Same as for `run_source_deps` but for 'build' stage.

### `run_build_metapackage`
arg1: package name

Build metapackage function. It should run proper script to build requested package

### `run_tar_build`
Run tar archive build

### `run_deploy_deps`
arg1: package name

Function is called when arg1 package should be deployed to internal package repository.

### `path_package_script`
arg1: package name

Print path to build.sh script relative to repository root.

### `docker_pre_run`
Function which will be called just before running docker create or docker run commands. Used to set proper `PLATFORM_ARCH`.

## Environment variables
### `PACKAGES=( )`, `DEPENDS=( )`, `METAPACKAGES=( )` arrays
Arrays to list packages supported in current environment. `PACKAGES` array is mandatory.

### `opt_*_arch` arrays

The `opt_*_arch` variables are set as array from value passed in `--arch` param. All has initially same value as `arg_arch` variable. `env_load` can modify them to enable different architectures for different stages - for example on cross-compiled environments only host architecture is needed for dependencies, not all listed in `--arch`. If `--arch` is not set host architecture is used.

- `opt_build_arch` - array of architecture names used for build and source stages for regular packages.
- `opt_meta_arch` - arrays of architecture names used to build metapackages. Usually host architecture should be used.
- `opt_deps_arch` - array of architecture names for dependency build. On cross-compilation enabled environments host arch should be set. On emulated - target architecture.


## Helper functions

### `docker_image_run`
arg1: `build` or `source`
arg2-N: run command and its arguments

Run command in temporary docker container.

### `docker_build_image`
arg1: Dockerfile
arg2: image type: `build` or `source` (to resolve image name)

ENV:
 - `CTX_PATH` - build context root directory, default: ENV_TARGET_ROOT, or Dockerfile directory if ENV_TARGET_ROOT was not set
 - `ENV_TARGET_ROOT` - build context if CTX_PATH is not set
 - `PELION_DOCKER_PREFIX` - prefix to image name (passed as PREFIX arg to the build instance)
 - `DOCKER_BUILD_ARGS` - list additional build arguments (will prepend `--build-arg` on each element)
 - `PLATFORM_ARCH` - `--platform=$PLATFORM_ARCH` passed to docker if set (optional, default: no `--platform` arg)

NOTE: --pull flag required to workaround multiarch issue

Dockerfile arguments provided by this function (`--build-arg`):
- `USER_ID`
- `GROUP_ID`
- `PREFIX`

Build docker images using Dockerfile

### `run_command_build` and `run_command_source`
arg1-N: command to run with its arguments

Run command in docker container (temporary or reused) or natively if `--docker` is not set.

If docker image is missing it will be created.
