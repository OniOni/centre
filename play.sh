#!/bin/bash

set -eo pipefail

function usage() {
    echo "usage: ${0} -i image"
    echo "Mount current directory as an overlay and run in container."
    echo ""
    echo -e "  -b\tRather than point to image, point to Dockerfile."
    echo -e "  -o\tChoose location of overlay directory [WORKDIR/overlay]"
    echo -e "  -w\tChoose location of workdir (where ${0} places temporary files needed for execution) [.prjctz]"
    exit
}

function cleanup() {
    sudo umount "${tmpdir}/merged"
    rm -rf "${tmpdir}"
}

while getopts "p:i:b:o:w:h" opts; do
    case $opts in
        p)
            PROJECT_NAME="${OPTARG}"
            ;;
        i)
            IMAGE="${OPTARG}"
            ;;
        b)
            BUILD_FILE="${OPTARG}"
            ;;
        o)
            OVERLAY="${OPTARG}"
            ;;
        w)
            WORKDIR="${OPTARG}"
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

PROJECT_NAME=${PROJECT_NAME:-"$(basename $(pwd))"}
WORKDIR=${WORKDIR:-"$(pwd)/.prjctz"}
OVERLAY=${OVERLAY:-"${WORKDIR}/overlay"}

if [[ -z "${IMAGE}" ]]; then
    if [[ -n "${BUILD_FILE}" ]]; then
        podman build -f "${BUILD_FILE}" -t "${PROJECT_NAME}_devbox"
        IMAGE="${PROJECT_NAME}_devbox"
    else
        usage
    fi
fi

if [[ ! -e "${WORKDIR}" ]]; then
    mkdir "${WORKDIR}"
fi

mkdir -p "${OVERLAY}"

tmpdir=$(mktemp -p "${WORKDIR}" -d prjctz.XXX)
mkdir "${tmpdir}/work" "${tmpdir}/merged"

trap cleanup EXIT
sudo mount -t overlay overlay -olowerdir="$(pwd)",upperdir="${OVERLAY}",workdir="${tmpdir}/work" "${tmpdir}/merged/"

sudo docker run -v "${tmpdir}/merged":"/${PROJECT_NAME}" -w "/${PROJECT_NAME}" --rm -it "${IMAGE}" /bin/bash

sudo umount "${tmpdir}/merged"
rm -rf "${tmpdir}"
