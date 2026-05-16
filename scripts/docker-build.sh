#!/bin/bash
# v0.2.0 by RK on 2026-05-07

usage() {
    echo "Usage: $(basename "$0") [--user dockerUserName] [--name imageName] [--version imageVersion] [--help]"
    echo ""
    echo "Values can also be set in docker-build.conf (searched in current dir, then script dir)."
    echo ""
    echo "  --user     Docker Hub username"
    echo "  --name     Image name"
    echo "  --version  Image version/tag"
    echo "  --help     Show this help"
    exit 0
}

# Load config file (current dir takes precedence over script dir)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="docker-build.conf"

if [ -f "./${CONFIG_FILE}" ]; then
    source "./${CONFIG_FILE}"
elif [ -f "${SCRIPT_DIR}/${CONFIG_FILE}" ]; then
    source "${SCRIPT_DIR}/${CONFIG_FILE}"
fi

# CLI arguments override config file values
while [ $# -gt 0 ]; do
    case "$1" in
        --user)    dockerUserName="$2"; shift 2 ;;
        --name)    imageName="$2";      shift 2 ;;
        --version) imageVersion="$2";   shift 2 ;;
        --help)    usage ;;
        *) echo "Unknown argument: $1"; echo ""; usage ;;
    esac
done

# Validate required values
errors=()
[ -z "${dockerUserName}" ] && errors+=("dockerUserName is required (--user or docker-build.conf)")
[ -z "${imageName}" ]      && errors+=("imageName is required (--name or docker-build.conf)")
[ -z "${imageVersion}" ]   && errors+=("imageVersion is required (--version or docker-build.conf)")
[ ! -f "./Dockerfile" ]    && errors+=("no Dockerfile found in the current directory")

if [ ${#errors[@]} -gt 0 ]; then
    for err in "${errors[@]}"; do echo "Error: ${err}"; done
    echo ""
    usage
fi

platformCodeList="${platformCodeList:-amd64 arm64}"

# Log in to Docker Hub if needed
docker info | grep -q "Username"
isLogged=$?
if [ ${isLogged} -gt 0 ]; then
    echo "Logging in as ${dockerUserName}..."
    docker login -u ${dockerUserName}
fi

function build_image() {
    platformCode=${1}
    if [ -z "${platformCode}" ]; then
        echo "Missing Platform Code"
        return
    fi
    docker build --platform linux/${platformCode} -t ${dockerUserName}/${imageName}:${imageVersion}-${platformCode} .
    docker push ${dockerUserName}/${imageName}:${imageVersion}-${platformCode}
}

function create_manifest() {
    manifestVersion=${1}
    if [ -z "${manifestVersion}" ]; then
        echo "Missing Manifest Version"
        return
    fi
    docker manifest rm ${dockerUserName}/${imageName}:${manifestVersion}

    local ammendImageList=""
    for individualPlatformCode in ${platformCodeList}; do
        ammendImageList="${ammendImageList} --amend ${dockerUserName}/${imageName}:${imageVersion}-${individualPlatformCode}"
    done

    docker manifest create ${dockerUserName}/${imageName}:${manifestVersion} ${ammendImageList}
}

function build_image_and_create_manifest() {
    for individualPlatformCode in ${platformCodeList}; do
        build_image ${individualPlatformCode}
    done

    for label in "${imageVersion}" "latest"; do
        create_manifest ${label}
    done
}

function buildx_images() {
    if [ -z "${platformCodeList}" ]; then
        echo "Missing Platform Code List"
        return
    fi

    local buildxPlatformList=""
    local buildxPlatformListSeparator=""
    for individualPlatformCode in ${platformCodeList}; do
        buildxPlatformList="${buildxPlatformList}${buildxPlatformListSeparator}linux/${individualPlatformCode}"
        if [ -z "${buildxPlatformListSeparator}" ]; then
            buildxPlatformListSeparator=","
        fi
    done

    for label in "${imageVersion}" "latest"; do
        docker-buildx build --platform ${buildxPlatformList} -t ${dockerUserName}/${imageName}:${label} --push .
    done
}

# old way: build_image_and_create_manifest
buildx_images
