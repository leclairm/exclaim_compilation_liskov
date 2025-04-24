# Compiling icon-exclaim with Liskov substitution (Praveen K Pothapakula)

These instructions are valid on `santis` out of the box. On `balfrin`, they require the installation of `uenv` version `7.0.0` and `uv`.

## Clone this repo

Somewhere on `${SCRATCH}` for the step by step procedure, anywhere else for the wrapper script.

## Step by step procedure

1.  Start a user environment with the correct view activated. also export the view used as `${VIEW}` so that following scripts have access to it. 

For instance
``` shell
uenv start icon-wcp/v1:rc4 --view=icon
export VIEW=icon
```
or
``` shell
uenv start /capstor/store/cscs/userlab/cwd01/leclairm/uenvs/images/icon_25.2_v2.sqfs --view=default
export VIEW=default
```

2. Install dependencies

``` shell
./install_dependencies.sh [OPTIONS]
```

3. Configure and build

``` shell
./setup.sh
```

4. Check that the `build_dsl/bin/icon` executable was generated 

## Run the wrapper script

The `launch_build_liskov.sh` script creates a working directory in a default location on `${SCRATCH}` and executes the previously described steps. It provides a series of handy options for the uenv and view to be used, submitting the build to a compute node, running the build in the background on login nodes with `nohup`, choosing a working sub-directory or choosing alternative icon repo/branch

Check the usage with `./launch_build_liskov.sh -h`

```
❯ launch_build_liskov.sh -h

Usage: launch_build_liskov.sh REQUIRED_PARAMETERS OPTIONS

REQUIRED_PARAMETERS
  -u UENV,--uenv=UENV: activate UENV when building
  -v VIEW,--view=VIEW: Use the view VIEW of UENV

OPTIONS
  -h,--help: print this help
  -n,--nohup: run in the background. Caution: process cannot be stoped
  -s,--submit: submit build to compute node
  -a ACCOUNT,--account=ACCOUNT: when submitting use ACCOUNT
  -w WORKDIR,--workdir=WORKDIR: build in /capstor/scratch/cscs/leclairm/exclaim_compilation_liskov/WORKDIR
                                otherwise directly in /capstor/scratch/cscs/leclairm/exclaim_compilation_liskov
  --icon-repo=ICON_REPO: provide an icon repository (default: git@github.com:C2SM/icon-exclaim.git)
  --icon-branch=ICON_BRANCH: provide an icon branch (default: reverse_advection)
                             required when using --icon-repo
```

