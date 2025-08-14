#!/bin/bash

dockerUserName="rkuzner"
imageVersion="0.1.1"
imageName="docker-qpdf"

# to run this commands, you should be logged to docker-hub!
docker info | grep -q "Username"
isLogged=$?
if [ ${isLogged} -gt 0 ]; then
    echo "Logging in as ${dockerUserName}..."
    docker login -u ${dockerUserName}
fi

# build platform specific images
docker build --platform linux/amd64 -t ${dockerUserName}/${imageName}:${imageVersion}-amd64 .
docker push ${dockerUserName}/${imageName}:${imageVersion}-amd64

docker build --platform linux/arm64 -t ${dockerUserName}/${imageName}:${imageVersion}-arm64 .
docker push ${dockerUserName}/${imageName}:${imageVersion}-arm64

# create version specific manifest
docker manifest rm ${dockerUserName}/${imageName}:${imageVersion}
docker manifest create ${dockerUserName}/${imageName}:${imageVersion} \
--amend ${dockerUserName}/${imageName}:${imageVersion}-amd64 \
--amend ${dockerUserName}/${imageName}:${imageVersion}-arm64

docker manifest push ${dockerUserName}/${imageName}:${imageVersion}

# create latest manifest
docker manifest rm ${dockerUserName}/${imageName}:latest
docker manifest create ${dockerUserName}/${imageName}:latest \
--amend ${dockerUserName}/${imageName}:${imageVersion}-amd64 \
--amend ${dockerUserName}/${imageName}:${imageVersion}-arm64

docker manifest push ${dockerUserName}/${imageName}:latest
