# Compiling icon-exclaim with Liskov substitution (Praveen K Pothapakula)

These instructions are valid on `santis` out of the box. On `balfrin`, they require the installation of `uenv` version `7.0.0` and `uv`.

## Step by step

1.  Start a user environment with the correct view activated. also export the view as `${VIEW}` used so that following scripts have access to it. 

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
Then export the view used so that following scripts have access to it:

2. Install dependencies

``` shell
./install_dependencies.sh
```

3. Configure and build

``` shell
./setup.sh
```

4. Check that the `build_dsl/bin/icon` executable was generated 

## Run the wrapper script

The `build_liskov.sh` script creates a working directory in a default location on `${SCRATCH}` and executes the previously described steps. It provides a series of handy options for the uenv and view to be used, submitting the build to a compute node, running the build in the background on login nodes with `nohup` or choosing a working sub-directory.

Check `./build_liskov.sh -h` for the usage. 
