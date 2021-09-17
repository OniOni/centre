#!/bin/bash

set -eo pipefail

DEFAULT_PROJECT_NAME="$(basename $(pwd))"
DEFAULT_BASEDIR="${HOME}/.prjctz"

function usage() {
    echo "Usage: ${0} [options] image [--]"
    echo "Mount current directory as an overlay and run in container."
    echo ""
    echo -e "  -b\tRather than point to image, point to Dockerfile."
    echo -e "  -p\tProject name [${DEFAULT_PROJECT_NAME}]."
    echo -e "  -R\tMount current directory directly without overlay."

    echo -e "\n\nENVIRONMENTAL VARIABLES\n"
    echo -e "  WORKDIR\tChoose location of workdir (where ${0} places temporary files needed for execution) [${DEFAULT_BASEDIR}/\$PROJECT_NAME]."
    echo -e "  OVERLAY\tChoose location of overlay directory [\$WORKDIR/overlay]."
    exit
}

function cleanup() {
    sudo umount "${tmpdir}/merged"
    rm -rf "${tmpdir}"
}

while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do
    case $1 in
        -p)
            shift
            PROJECT_NAME="${1}"
            ;;
        -b)
            shift
            BUILD_FILE="${1}"
            ;;
        -R)
            RAW=1
            ;;
        -H)
            MOUNT_HOME=1
            ;;
        -h)
            usage
            ;;
        *)
            usage
            ;;
    esac
    shift
done

PROJECT_NAME=${PROJECT_NAME:-"${DEFAULT_PROJECT_NAME}"}
WORKDIR=${WORKDIR:-"${DEFAULT_BASEDIR}/${PROJECT_NAME}"}
OVERLAY=${OVERLAY:-"${WORKDIR}/overlay"}
RAW=${RAW:-0}

if [[ -n "$1" ]]; then
    IMAGE="$1"
else
    usage
fi

shift
if [[ "$1" == "--" ]]; then
    shift
    ARGS="${*}"
fi

if [[ -z "${IMAGE}" ]]; then
    if [[ -n "${BUILD_FILE}" ]]; then
        sudo docker build -f "${BUILD_FILE}" -t "${PROJECT_NAME}_devbox" .
        IMAGE="${PROJECT_NAME}_devbox"
    else
        usage
    fi
fi

if [[ ! -e "${WORKDIR}" ]]; then
    mkdir -p "${WORKDIR}"
fi

mkdir -p "${OVERLAY}"

if [[ "${RAW}" == "0" ]]; then
    tmpdir=$(mktemp -p "${WORKDIR}" -d prjctz.XXX)
    mkdir "${tmpdir}/work" "${tmpdir}/merged"

    trap cleanup EXIT
    sudo mount -t overlay overlay -olowerdir="$(pwd)",upperdir="${OVERLAY}",workdir="${tmpdir}/work" "${tmpdir}/merged/"
    disk="${tmpdir}/merged"
else
    disk="$(pwd)"
fi

MOUNTS=""
if [[ "${MOUNT_HOME}" -eq 1 ]]; then
    MOUNTS+=("--mount type=bind,src=${HOME},dst=/root,ro")
fi

sudo docker run -v "${disk}":"/${PROJECT_NAME}" -w "/${PROJECT_NAME}" \
     --rm -it ${MOUNTS[@]} ${ARGS[@]} "${IMAGE}" /bin/bash
