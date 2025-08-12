#!/bin/bash -l 
set -e -x

# Check setup branches are set
check_var_set(){
   if eval "[ -z \${${1}+x} ]"; then
       echo "ERROR: $1 not set"
       exit 1
   fi
}
for var in "ICON_REPO ICON_BRANCH ICON4PY_BRANCH GT4PY_BRANCH GRIDTOOLS_BRANCH"; do
  check_var_set "${var}"
done

# Clone with specific branches
git clone --depth 1 --recurse-submodules --shallow-submodules -b "${ICON_BRANCH}" "${ICON_REPO}"
git clone --depth 1 -b "${ICON4PY_BRANCH}" git@github.com:C2SM/icon4py.git
git clone --depth 1 -b "${GT4PY_BRANCH}" https://github.com/GridTools/gt4py.git
git clone --depth 1 -b "${GRIDTOOLS_BRANCH}" https://github.com/GridTools/gridtools.git

# Fix wrong requirements in icon4py v0.0.14
if [ "${ICON4PY_BRANCH}" == "v0.0.14" ]; then
    cat <<EOB > icon4py/requirements.txt
-r base-requirements.txt

# icon4py model
./model/atmosphere/dycore
./model/atmosphere/diffusion
./model/atmosphere/advection
./model/atmosphere/subgrid_scale_physics/microphysics
./model/common[io]
./model/driver

# icon4pytools
./tools
EOB
fi

# Fix base-requirements
echo "gt4py @ git+https://github.com/GridTools/gt4py.git@${GT4PY_BRANCH}" > icon4py/base-requirements.txt

# copy buid script to build directory
cp  nospack.dsl.nvidia.sh icon-exclaim/config/cscs/build.nospack.dsl.nvidia.sh

# Install icon4py virtual environment
pushd icon4py
if [ "${USE_PIP}" == "true" ]; then
    python3.10 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade wheel
    pip install --upgrade pip
    pip install -r requirements.txt
    deactivate
else
    if ! which uv > /dev/null 2>&1; then
        echo "ERROR: no uv found"
        exit 1
    fi
    export UV_LINK_MODE=copy
    uv venv --python "$(realpath "$(which python)")"
    CC=nvc CFLAGS=-noswitcherror uv pip install --no-cache -r requirements.txt
fi
popd
