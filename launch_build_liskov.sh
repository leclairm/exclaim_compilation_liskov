#!/bin/bash

ROOT_WORK_DIR_ESC="\${SCRATCH}/exclaim_compilation_liskov"
eval "ROOT_WORK_DIR=${ROOT_WORK_DIR_ESC}"
SUBMIT=false
NOHUP=false
USE_PIP="false"
JSBACH="--disable-jsbach"

usage(){
    echo ""
    echo "Usage: $(basename $0) REQUIRED_PARAMETERS OPTIONS"
    echo ""
    echo "REQUIRED_PARAMETERS"
    echo "  -s SETUP_FILE, --setup=SETUP_FILE: use dependencies versions from SETUP_FILE"
    echo "  -u UENV, --uenv=UENV: activate UENV when building"
    echo "  -v VIEW, --view=VIEW: Use the view VIEW of UENV"
    echo ""
    echo "OPTIONS"
    echo "  -h, --help: print this help"
    echo "  -n, --nohup: run in the background. CAUTION: process cannot be stoped"
    echo "  --use-pip: use pip instead of uv"
    echo "  --submit ACCOUNT: submit build to compute node and use ACCOUNT"
    echo "  -w WORKDIR, --workdir=WORKDIR: build in ${ROOT_WORK_DIR_ESC}/WORKDIR"
    echo "                                 otherwise directly in ${ROOT_WORK_DIR_ESC}"
    echo ""
}

check_opt_val(){
    if [[ "${2:0:1}" == "-" ]]; then
        usage
        echo "ERROR: $1 expects a value, got option $2"
        exit 1
    fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0;;
    -n|--nohup) NOHUP=true; shift 1;;
    --use-pip) USE_PIP=true; shift 1;;
    -s) check_opt_val "$1" "$2"; SETUP="$2"; shift 2;;
    -u) check_opt_val "$1" "$2"; UENV="$2"; shift 2;;
    -v) check_opt_val "$1" "$2"; VIEW="$2"; shift 2;;
    -w) check_opt_val "$1" "$2"; SUB_WORK_DIR="$2"; shift 2;;

    --setup=*) SETUP="${1#*=}"; shift 1;;
    --uenv=*) UENV="${1#*=}"; shift 1;;
    --view=*) VIEW="${1#*=}"; shift 1;;
    --submit=*) SUBMIT_ACCOUNT="${1#*=}"; shift 1;;
    --workdir=*) SUB_WORK_DIR="${1#*=}"; shift 1;;
    --uenv|--view|--submit|--work_dir|--setup)
        usage
        echo "ERROR: $1 requires an argument with ${1}=VALUE" >&2
        exit 1
        ;;

    *) usage; echo "ERROR: unknown option: $1" >&2; exit 1;;
  esac
done

# Check required options
if [ -z ${SETUP} ]; then
    usage
    echo "ERROR: no setup chosen"
    exit 1
fi
if [ -z ${UENV} ] || [ -z ${VIEW} ]; then
    usage
    echo "ERROR: uenv and view are required"
    exit 1
fi

# WORK_DIR
WORK_DIR="${ROOT_WORK_DIR}"
[ -n ${SUB_WORK_DIR} ] && WORK_DIR="${WORK_DIR}/${SUB_WORK_DIR}"

# log configuration
echo "build config"
echo "------------"
echo "  - setup: ${SETUP}"
echo "  - workdir: ${WORK_DIR}"
echo "  - use pip: ${USE_PIP}"
echo "  - uenv: ${UENV}"
echo "  - view: ${VIEW}"
if [ -n "${SUBMIT_ACCOUNT}" ]; then
    echo "  - submit build: true"
    echo "  - submit account: ${SUBMIT_ACCOUNT}"
else
    echo "  - submit build: false"
    echo "  - nohup execution: ${NOHUP}"
fi
echo ""

mkdir -p ${WORK_DIR}
rm -rf ${WORK_DIR}/*

rsync -av --exclude $(basename $0) --exclude README.md --exclude=".*" ./ ${WORK_DIR}/

pushd ${WORK_DIR} 2>&1 > /dev/null || exit 1

BUILD_SCRIPT="build_liskov.sh"
BUILD_LOG="${BUILD_SCRIPT%%.*}.o"

cat <<EOB > ${BUILD_SCRIPT}
#!/bin/bash

#SBATCH --nodes=1
#SBATCH --constraint=gpu
#SBATCH --time=01:00:00
#SBATCH --output ${BUILD_LOG}
#SBATCH --error ${BUILD_LOG}
#SBATCH --uenv ${UENV}
#SBATCH --view ${VIEW}
EOB

[ -n "${SUBMIT_ACCOUNT}" ] && echo "#SBATCH --account ${SUBMIT_ACCOUNT}" >> ${BUILD_SCRIPT}

cat <<EOB >> ${BUILD_SCRIPT}

set -e

export VIEW=${VIEW}
export USE_PIP=${USE_PIP}

source ${SETUP}
./install_dependencies.sh || exit 1
./setup.sh || exit 1

EOB

chmod 755 ${BUILD_SCRIPT}

if [ -n "${SUBMIT_ACCOUNT}" ]; then
    sbatch ${BUILD_SCRIPT}
    echo "build submitted, follow with the following command"
    echo "tail -f $(realpath ${BUILD_LOG})"
else
    COMMAND="uenv run ${UENV} --view ${VIEW} time ./${BUILD_SCRIPT}"
    if [ "${NOHUP}" == "true" ]; then
        WRAPPER_SCRIPT="wrapper.sh"
        echo ${COMMAND} > ${WRAPPER_SCRIPT}
        chmod 755 ${WRAPPER_SCRIPT}
        nohup ./${WRAPPER_SCRIPT} 2>&1 > ${BUILD_LOG} &
        echo "running in the background, follow build  with the following command"
        echo "tail -f $(realpath ${BUILD_LOG})"
    else
        ${COMMAND} 2>&1 | tee ${BUILD_LOG}
    fi
fi
