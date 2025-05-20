#!/bin/bash -l 
set -e -x

# Default branches if not provided
icon_repo="git@github.com:C2SM/icon-exclaim.git"
icon_branch="reverse_advection"
icon4py_branch="v0.0.14"
gt4py_branch="icon4py_20241113"
gridtools_branch="v2.3.7"

while [ "$1" != "" ]; do
    case $1 in
        --icon-repo )   shift
                        icon_repo=$1
                        ;;
        --icon-branch ) shift
                        icon_branch=$1
                        ;;
        --icon4py )     shift
                        icon4py_branch=$1
                        ;;
        --gt4py )       shift
                        gt4py_branch=$1
                        ;;
        --gridtools )   shift
                        gridtools_branch=$1
                        ;;
        * )             echo "Invalid option"
                        exit 1
    esac
    shift
done

# Clone with specific branches
git clone --depth 1 --recurse-submodules --shallow-submodules -b $icon_branch $icon_repo
git clone --depth 1 -b $icon4py_branch git@github.com:C2SM/icon4py.git
cp -r base-requirements.txt icon4py  
cp -r requirements.txt icon4py
git clone --depth 1 -b $gt4py_branch https://github.com/GridTools/gt4py.git
git clone --depth 1 -b $gridtools_branch https://github.com/GridTools/gridtools.git

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
    if which uv > /dev/null 2>&1; then
        echo "ERROR: no uv found"
        exit 1
    fi
    export UV_LINK_MODE=copy
    export UV_PYTHON="/user-environment/env/${VIEW}/bin/python"
    uv venv --python $(python --version | awk '{print $2}')
    uv pip install --upgrade wheel
    uv pip install --upgrade pip
    CC=nvc CFLAGS=-noswitcherror uv pip install --no-cache -r requirements.txt
fi
popd
