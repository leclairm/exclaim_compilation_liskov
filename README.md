# Compiling icon-exclaim with Liskov substitution

The preferred strategy is the [launching script](#launching-script) described below.

## Clone this repo

``` shell
git clone -b icon_blue https://github.com/leclairm/exclaim_compilation_liskov.git
```

Somewhere on `${SCRATCH}` for the step by step procedure, anywhere else for the launching script approach.

## Step by step procedure

1.  Start a user environment with the correct view activated, e.g. `uenv start icon/25.2:v3 --view=default` or `uenv start icon-wcp/v1:rc4 --view=icon`

2. source your setup
``` shell
source my_setup.sh
```

3. Install dependencies

``` shell
./install_dependencies.sh
```

4. Configure and build

``` shell
./setup.sh
```

5. Check that the `build_dsl/bin/icon` executable was generated 

## Launching script

The `launch_build_liskov.sh` script creates a working directory in a default location on `${SCRATCH}` and executes the previously described steps. It provides a series of handy options for selecting the setup, the uenv and view to be used, submitting the build to a compute node, running the build in the background on login nodes with `nohup` or choosing a working sub-directory

Check the usage with `./launch_build_liskov.sh -h`

```
❯ ./launch_build_liskov.sh -h

Usage: launch_build_liskov.sh REQUIRED_PARAMETERS OPTIONS

REQUIRED_PARAMETERS
  -s SETUP_FILE, --setup=SETUP_FILE: use dependencies versions from SETUP_FILE
  -u UENV, --uenv=UENV: activate UENV when building
  -v VIEW, --view=VIEW: Use the view VIEW of UENV

OPTIONS
  -h, --help: print this help
  -n, --nohup: run in the background. CAUTION: process cannot be stoped
  --use-pip: use pip instead of uv
  --submit=ACCOUNT: submit build to compute node and use ACCOUNT
  -w WORKDIR, --workdir=WORKDIR: build in ${SCRATCH}/exclaim_compilation_liskov/WORKDIR
                                 otherwise directly in ${SCRATCH}/exclaim_compilation_liskov
```

