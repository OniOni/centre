#!/bin/bash

set -eo pipefail

function usage() {
    echo "usage:"
    exit
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
            WORKDIR="${WORKDIR}"
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
WORKDIR=${WORKDIR:-".prjctz"}
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

sudo mount -t overlay overlay -olowerdir="$(pwd)",upperdir="${OVERLAY}",workdir="${tmpdir}/work" "${tmpdir}/merged/"

podman run -v "${tmpdir}/merged":"/$(dirname $(pwd))" -w "/$(dirname $(pwd))" --rm -it "${IMAGE}" /bin/bash

sudo umount "${tmpdir}/merged"
rm -rf "${tmpdir}"
