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
cp -r nospack.dsl.nvidia_PPK icon-exclaim/config/cscs/
git clone --depth 1 -b $icon4py_branch git@github.com:C2SM/icon4py.git
cp -r base-requirements.txt icon4py  
cp -r requirements.txt icon4py
git clone --depth 1 -b $gt4py_branch https://github.com/GridTools/gt4py.git
git clone --depth 1 -b $gridtools_branch https://github.com/GridTools/gridtools.git

pushd icon4py

# - ML - use uv
uv --version || exit 1
uv venv --python $(python --version | awk '{print $2}')
uv pip install --upgrade wheel
uv pip install --upgrade pip
uv pip install -r requirements.txt

# python3.10 -m venv .venv
# source .venv/bin/activate
# pip install --upgrade wheel
# pip install --upgrade pip
# pip install -r requirements.txt

popd

# deactivate
