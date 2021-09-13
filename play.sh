#!/bin/bash

set -eo pipefail

function usage() {
    echo "stuff"
    exit
}

while getopts "p:i:b:h" opts; do
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
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# BASEIMAGE="docker.io/library/${BASEIMAGE:-ubuntu}"
PROJECT_NAME=${PROJECT_NAME:-"$(basename $(pwd))"}

if [[ -z "${PROJECT_NAME}" && -n "${BUILD_FILE}" ]]; then
    cd .prjctz
    podman build -f Dockerfile -t "${PROJECT_NAME}_devbox"
    IMAGE="${PROJECT_NAME}_devbox"
    cd ..
fi

mkdir -p ".prjctz/overlay"

tmpdir=$(mktemp -p .prjctz/ -d prjctz.XXX)
mkdir "${tmpdir}/work" "${tmpdir}/merged"

sudo mount -t overlay overlay -olowerdir="$(pwd)",upperdir=".prjctz/overlay",workdir="${tmpdir}/work" "${tmpdir}/merged/"

# podman pull "${BASEIMAGE}"
podman run -v "${tmpdir}/merged":"/$(dirname $(pwd))" -w "/$(dirname $(pwd))" --rm -it "${IMAGE}" /bin/bash

sudo umount "${tmpdir}/merged"
rm -rf "${tmpdir}"
