#!/bin/bash
set -e -x

# Core dependencies (Spack)
source ./todi_env.sh

root_path=$(pwd)



# Set compile time arguments
#SERIALBOX2_ROOT=$(spack find --format "{prefix}" serialbox@2.6.0%pgi | head -n1)
#XML2_ROOT=$(spack find --format "{prefix}" libxml2 | head -n1)
#ECCODES_ROOT=$(spack find --format "{prefix}" eccodes@2.19.0%pgi +build_shared_libs | head -n1)

XML2_ROOT="/user-environment/linux-sles15-neoverse_v2/gcc-12.3.0/libxml2-2.10.3-7bjhm4gkxtzf4hfmugjv2ivcplisiwf7"

LOC_GT4PY=${root_path}/gt4py/
LOC_ICON4PY_ATM_DYN_ICONAM=${root_path}/icon4py/model/atmosphere/dycore/src/icon4py/model/atmosphere/dycore/
LOC_ICON4PY_ADVECTION=${root_path}/icon4py/model/atmosphere/advection/src/icon4py/model/atmosphere/advection/
LOC_ICON4PY_DIFFUSION=${root_path}/icon4py/model/atmosphere/diffusion/src/icon4py/model/atmosphere/diffusion/stencils
LOC_ICON4PY_INTERPOLATION=${root_path}/icon4py/model/common/src/icon4py/model/common/interpolation/stencils
LOC_ICON4PY_TOOLS=${root_path}/icon4py/tools/src/icon4pytools/
LOC_ICON4PY_BIN=${root_path}/icon4py/.venv/
LOC_GRIDTOOLS=${root_path}/gridtools/


    # Compile and run ICON based on the build type
pushd icon-exclaim
#        Sorry this has to be manually done due to issues with git via ssh or https 
       git submodule update --init --recursive   
  
   mkdir -p build_dsl
   pushd build_dsl


 #SERIALBOX2_ROOT=$SERIALBOX2_ROOT  \
 XML2_ROOT=$XML2_ROOT \
 ECCODES_ROOT=$ECCODES_ROOT \
 LOC_GT4PY=$LOC_GT4PY \
 LOC_ICON4PY_ATM_DYN_ICONAM=$LOC_ICON4PY_ATM_DYN_ICONAM \
 LOC_ICON4PY_ADVECTION=$LOC_ICON4PY_ADVECTION \
 LOC_ICON4PY_DIFFUSION=$LOC_ICON4PY_DIFFUSION \
 LOC_ICON4PY_INTERPOLATION=$LOC_ICON4PY_INTERPOLATION \
 LOC_ICON4PY_TOOLS=$LOC_ICON4PY_TOOLS \
 LOC_ICON4PY_BIN=$LOC_ICON4PY_BIN \
 LOC_GRIDTOOLS=$LOC_GRIDTOOLS \
 ./../config/cscs/todi_nospack.dsl.nvidia_PPK -disable-rte-rrtmgp --enable-liskov=substitute --disable-liskov-fused 

make -j20

