#!/bin/bash

ROOT_WORK_DIR="${SCRATCH}/exclaim_compilation_liskov"
SUBMIT=false
NOHUP=false
SBATCH="sbatch"
DEFAULT_ICON_REPO="git@github.com:C2SM/icon-exclaim.git"
DEFAULT_ICON_BRANCH="reverse_advection"

usage(){
    echo ""
    echo "Usage: $(basename $0) REQUIRED_PARAMETERS OPTIONS"
    echo ""
    echo "REQUIRED_PARAMETERS"
    echo "  -u UENV,--uenv=UENV: activate UENV when building"
    echo "  -v VIEW,--view=VIEW: Use the view VIEW of UENV"
    echo ""
    echo "OPTIONS"
    echo "  -h,--help: print this help"
    echo "  -n,--nohup: run in the background. Caution: process cannot be stoped"
    echo "  -s,--submit: submit build to compute node"
    echo "  -a ACCOUNT,--account=ACCOUNT: when submitting use ACCOUNT"
    echo "  -w WORKDIR,--workdir=WORKDIR: build in ${ROOT_WORK_DIR}/WORKDIR"
    echo "                                otherwise directly in ${ROOT_WORK_DIR}"
    echo "  --icon-repo=ICON_REPO: provide an icon repository (default: ${DEFAULT_ICON_REPO})"
    echo "  --icon-branch=ICON_BRANCH: provide an icon branch (default: ${DEFAULT_ICON_BRANCH})"
    echo "                             required when using --icon-repo"
    echo ""
}

check_opt_val(){
    if [[ "${2:0:1}" == "-" ]]; then
        usage
        echo "$1 expects a value, got option $2"
        exit 1
    fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0;;
    -n|--nohup) NOHUP=true; shift 1;;
    -s|--submit) SUBMIT=true; shift 1;;
    -a) check_opt_val "$1" "$2"; SBATCH="${SBATCH} --account $2"; shift 2;;
    -u) check_opt_val "$1" "$2"; UENV="$2"; shift 2;;
    -v) check_opt_val "$1" "$2"; VIEW="$2"; shift 2;;
    -w) check_opt_val "$1" "$2"; SUB_WORK_DIR="$2"; shift 2;;

    --uenv=*) UENV="${1#*=}"; shift 1;;
    --view=*) VIEW="${1#*=}"; shift 1;;
    --account=*) SBATCH="${SBATCH} --account ${1#*=}"; shift 1;;
    --workdir=*) SUB_WORK_DIR="${1#*=}"; shift 1;;
    --icon-repo=*) ICON_REPO="${1#*=}"; shift 1;;
    --icon-branch=*) ICON_BRANCH="${1#*=}"; shift 1;;
    --uenv|--view|--account|--work_dir|--icon-repo|--icon-branch)
        usage
        echo "ERROR: $1 requires an argument with ${1}=VALUE" >&2
        exit 1
        ;;

    *) usage; echo "ERROR: unknown option: $1" >&2; exit 1;;
  esac
done

# ICON repo and branch
if [[ -n ${ICON_REPO} && -z ${ICON_BRANCH} ]]; then
   usage
   echo "ERROR: --icon-repo also needs --icon-branch to be specified"
   exit 1
fi
: "${ICON_REPO:=${DEFAULT_ICON_REPO}}"
: "${ICON_BRANCH:=${DEFAULT_ICON_BRANCH}}"

# WORK_DIR
WORK_DIR="${ROOT_WORK_DIR}"
[[ -n ${SUB_WORK_DIR} ]] && WORK_DIR="${WORK_DIR}/${SUB_WORK_DIR}"

if [[ -z ${UENV} || -z ${VIEW} ]]; then
    usage
    echo "ERROR: uenv and view are required"
    exit 1
fi

# log configuration
echo "build config"
echo "------------"
echo "  - icon repo: ${ICON_REPO}"
echo "  - icon branch: ${ICON_BRANCH}"
echo "  - Workdir: ${WORK_DIR}"
echo "  - uenv: ${UENV}"
echo "  - view: ${VIEW}"
echo "  - submit build: ${SUBMIT}"
echo "  - nohup execution: ${NOHUP}"
echo ""

mkdir -p ${WORK_DIR}
rm -rf ${WORK_DIR}/*

rsync -av --exclude $(basename $0) --exclude README.md ./ ${WORK_DIR}/

pushd ${WORK_DIR} 2>&1 > /dev/null || exit 1

BUILD_SCRIPT="build_liskov.sh"

cat <<EOB > ${BUILD_SCRIPT}
#!/bin/bash

#SBATCH --nodes=1
#SBATCH --constraint=gpu
#SBATCH --time=01:00:00
#SBATCH --output build_liskov.o
#SBATCH --error build_liskov.o
#SBATCH --uenv ${UENV}
#SBATCH --view ${VIEW}

export VIEW=${VIEW}

./install_dependencies.sh --icon-repo ${ICON_REPO} --icon-branch ${ICON_BRANCH}  || exit 1
./setup.sh || exit 1

EOB

chmod 755 ${BUILD_SCRIPT}

if [[ "${SUBMIT}" == "true" ]]; then
    ${SBATCH} ${BUILD_SCRIPT}
else
    COMMAND="uenv run ${UENV} --view ${VIEW} time ./${BUILD_SCRIPT}"
    if [[ "${NOHUP}" == "true" ]]; then
        WRAPPER_SCRIPT="wrapper.sh"
        echo ${COMMAND} > ${WRAPPER_SCRIPT}
        chmod 755 ${WRAPPER_SCRIPT}
        nohup ./${WRAPPER_SCRIPT} 2>&1 > ${BUILD_SCRIPT%%.*}.o &
        echo "running in the background, follow build with \"tail -f $(realpath ${BUILD_SCRIPT%%.*}.o)\""
    else
        ${COMMAND}
    fi
fi
