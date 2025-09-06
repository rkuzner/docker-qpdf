#!/bin/bash

dockerUserName="rkuzner"
imageName="docker-qpdf"
imageVersion="0.1.2"
platformCodeList="amd64 arm64"

# to run this commands, you should be logged to docker-hub!
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
    # build platform specific images
    for individualPlatformCode in ${platformCodeList}; do
        build_image ${individualPlatformCode}
    done

    # create manifests
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
        echo "DEBUG: docker buildx build --platform ${buildxPlatformList} -t ${dockerUserName}/${imageName}:${label} --push ."
        docker-buildx build --platform ${buildxPlatformList} -t ${dockerUserName}/${imageName}:${label} --push .
    done
}


# now create images
# old way: build_image_and_create_manifest
buildx_images
