#!/bin/bash                                                                                                                                                                                                 

set -exo pipefail

DEFAULT_PROJECT_NAME="$(basename $(pwd))"
DEFAULT_BASEDIR="${HOME}/.prjctz"

function usage() {
    echo "usage: ${0} -i image"
    echo "Mount current directory as an overlay and run in container."
    echo ""
    echo -e "  -b\tRather than point to image, point to Dockerfile."
    echo -e "  -p\tProject name [${DEFAULT_PROJECT_NAME}]."
    echo -e "  -R\tMount current directory directly without overlay."

    echo -e "\n\nADVANCED\n"
    echo -e "  -w\tChoose location of workdir (where ${0} places temporary files needed for execution) [${DEFAULT_BASEDIR}/\$PROJECT_NAME]."
    echo -e "  -o\tChoose location of overlay directory [\$WORKDIR/overlay]."
    exit
}

function cleanup() {
    sudo umount "${tmpdir}/merged"
    rm -rf "${tmpdir}"
}


while getopts "p:i:b:o:w:hR" opts; do
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
        R)
            RAW=1
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

PROJECT_NAME=${PROJECT_NAME:-"${DEFAULT_PROJECT_NAME}"}
WORKDIR=${WORKDIR:-"${DEFAULT_BASEDIR}/${PROJECT_NAME}"}
OVERLAY=${OVERLAY:-"${WORKDIR}/overlay"}
RAW=${RAW:-0}

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

sudo docker run -v "${disk}":"/${PROJECT_NAME}" -w "/${PROJECT_NAME}" --rm -it "${IMAGE}" /bin/bash
