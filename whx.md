

docker buildx create --name mycustombuilder --driver docker-container --bootstrap



docker  buildx use mycustombuilder



docker  buildx build --platform linux/arm64,linux/amd64 \
--build-arg VCS_REF=`git rev-parse --short HEAD` \
--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
--build-arg CANAL_COMPONENT_VERSION="1.1.7" \
--build-arg CANAL_COMPONENT_NAME="canal-adapter" \
--build-arg CANAL_DOWNLOAD_NAME="canal.adapter" \
-t wanghongxing/canal-adapter:v1.1.7 . --push