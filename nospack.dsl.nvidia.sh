#!/bin/bash

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)
ICON_DIR=$(cd "${SCRIPT_DIR}/../.."; pwd)


UENV_VIEW_PATH="/user-environment/env/${VIEW}"

# Uncomment to use
# SERIALBOX2_LIBS='-lSerialboxFortran -lSerialboxC -lSerialboxCore'
# SB2PP="python2 ${UENV_VIEW_PATH}/python/pp_ser/pp_ser.py"
# ECCODES_LIBS='-leccodes' # - ML - appears unsued

# - ML - to avoid failure because of set -u
SERIALBOX2_LIBS=""
SB2PP=""

# Mandatory LIBS
XML2_LIBS='-lxml2'
BLAS_LAPACK_LIBS='-llapack -lblas'
NETCDF_LIBS='-lnetcdf -lnetcdff'
# The rest of libraries required by CUDA will be provided by PGI compiler:
STDCPP_LIBS='-c++libs'

################################################################################

CC='mpicc'
CFLAGS='-g -O2'
CPPFLAGS="-I${UENV_VIEW_PATH}/include/libxml2 -I${UENV_VIEW_PATH}/include"
CXX='mpicxx'

FC='mpif90'
FCFLAGS="-I${UENV_VIEW_PATH}/include -g -traceback -O -Mrecursive -Mallocatable=03 -Mbackslash -Mstack_arrays -acc=verystrict -gpu=cc90 -Minfo=accel,inline -D__USE_G2G -D__SWAPDIM"
LDFLAGS="-L${UENV_VIEW_PATH}/lib64 -L${UENV_VIEW_PATH}/lib"
DSL_LDFLAGS="-L${UENV_VIEW_PATH}/lib64 -L${UENV_VIEW_PATH}/lib"

LIBS="-L${CUDA_HOME}/lib64 -lcudart -Wl,--as-needed ${XML2_LIBS} ${BLAS_LAPACK_LIBS} ${SERIALBOX2_LIBS} ${STDCPP_LIBS} ${NETCDF_LIBS}"

CUDAARCHS='90'
# NVCC='nvcc'
# -G seems to break the build, at least it does on tsa
GT4PYNVCFLAGS='--std=c++17 -arch=sm_90 -g -O3 -lineinfo'
NVCFLAGS='-ccbin mpic++ -g -O3 -arch=sm_90'
# gt4py NVCFLAGS need to be frozen, since -I/path/to/external/cub is added for NVCFLAGS in configure, which will break the build for gt4py.

#MPI_LAUNCH='/apps/daint/UES/xalt/production/bin/srun -p debug -C gpu'
MPI_LAUNCH=false

EXTRA_CONFIG_ARGS='--disable-loop-exchange --disable-ocean --enable-gpu=openacc+cuda --disable-rte-rrtmgp --enable-ecrad'

# Speed up the configuration by disabling MPI checks:
EXTRA_CONFIG_ARGS+=' --disable-mpi-checks --disable-coupling'
EXTRA_CONFIG_ARGS+=' --disable-rpaths --enable-atmo --enable-les --enable-upatmo --disable-jsbach --disable-waves --disable-aes  --disable-rttov --enable-acm-license --enable-mpi  --disable-openmp --enable-realloc-buf  --disable-parallel-netcdf --disable-sct --disable-yaxt --disable-testbed --disable-vectorized-lrtm --disable-mixed-precision --enable-pgi-inlib --disable-nccl --disable-cuda-graphs --enable-silent-rules --disable-serialization --enable-mpi-gpu'

# [DSL] In order to enable DSL verification mode, pass --enable-dsl-verify to this script

check_path(){
   if eval "[ -z \${${1}+x} ]"; then
       echo "$2 path not set. Must be et through \${$1}"
       exit 1
   fi
}

check_path "LOC_GT4PY" "gt4py"
check_path "LOC_ICON4PY_ATM_DYN_ICONAM" "icon4py dycore"
check_path "LOC_ICON4PY_ADVECTION" "icon4py advection"
check_path "LOC_ICON4PY_DIFFUSION" "icon4py diffusion"
check_path "LOC_ICON4PY_INTERPOLATION" "icon4py interpolation"
check_path "LOC_ICON4PY_TOOLS" "icon4py tools"
check_path "LOC_ICON4PY_BIN" "icon4py binary"
check_path "LOC_GRIDTOOLS" "gridtools"


################################################################################
"${ICON_DIR}/configure" \
CC="$CC" \
CFLAGS="$CFLAGS" \
CPPFLAGS="$CPPFLAGS" \
CXX="$CXX" \
FC="$FC" \
CUDAARCHS="$CUDAARCHS" \
NVCFLAGS="$NVCFLAGS" \
FCFLAGS="$FCFLAGS" \
LDFLAGS="$LDFLAGS" \
DSL_LDFLAGS="$DSL_LDFLAGS" \
LIBS="$LIBS" \
MPI_LAUNCH="$MPI_LAUNCH" \
GT4PYNVCFLAGS="$GT4PYNVCFLAGS" \
SB2PP="$SB2PP" \
LOC_GT4PY="$LOC_GT4PY" \
LOC_ICON4PY_ATM_DYN_ICONAM="$LOC_ICON4PY_ATM_DYN_ICONAM" \
LOC_ICON4PY_ADVECTION="$LOC_ICON4PY_ADVECTION" \
LOC_ICON4PY_DIFFUSION="$LOC_ICON4PY_DIFFUSION" \
LOC_ICON4PY_INTERPOLATION="$LOC_ICON4PY_INTERPOLATION" \
LOC_ICON4PY_TOOLS="$LOC_ICON4PY_TOOLS" \
LOC_ICON4PY_BIN="$LOC_ICON4PY_BIN" \
LOC_GRIDTOOLS="$LOC_GRIDTOOLS" \
${EXTRA_CONFIG_ARGS} \
"$@"


make -j20
#srun -p pp-short -N 1 -c 20 -- make -j20


for arg in "$@"; do
  case $arg in
    -help | --help | --hel | --he | -h | -help=r* | --help=r* | --hel=r* | --he=r* | -hr* | -help=s* | --help=s* | --hel=s* | --he=s* | -hs*)
      test -n "${EXTRA_CONFIG_ARGS}" && echo '' && echo "This wrapper script ('$0') calls the configure script with the following extra arguments, which might override the default values listed above: ${EXTRA_CONFIG_ARGS}"
      exit 0 ;;
  esac
done

# Copy runscript-related files when building out-of-source:
if test $(pwd) != $(cd "${ICON_DIR}"; pwd); then
  echo "Copying runscript input files from the source directory..."
  rsync -uavz ${ICON_DIR}/run . --exclude='*.in' --exclude='.*' --exclude='standard_*'
  ln -sf -t run/ ${ICON_DIR}/run/standard_*
  rsync -uavz ${ICON_DIR}/externals . --exclude='.git' --exclude='*.f90' --exclude='*.F90' --exclude='*.c' --exclude='*.h' --exclude='*.Po' --exclude='tests' --exclude='*.mod' --exclude='*.o'
  rsync -uavz ${ICON_DIR}/make_runscripts .
  ln -sf ${ICON_DIR}/data
  ln -sf ${ICON_DIR}/vertical_coord_tables
fi
