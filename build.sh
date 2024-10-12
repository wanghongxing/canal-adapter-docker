#生成我打完补丁的镜像

# build canal adapter
docker  buildx build --platform linux/arm64,linux/amd64 \
--build-arg VCS_REF=`git rev-parse --short HEAD` \
--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
--build-arg CANAL_COMPONENT_VERSION="1.1.7" \
--build-arg CANAL_COMPONENT_NAME="canal-adapter" \
--build-arg CANAL_DOWNLOAD_NAME="canal.adapter" \
-t wanghongxing/canal-adapter:v1.1.7 -t wanghongxing/canal-adapter:latest -f Dockerfile . --push



# build canal adapter
docker    build --platform linux/amd64 \
--build-arg VCS_REF=`git rev-parse --short HEAD` \
--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
--build-arg CANAL_COMPONENT_VERSION="1.1.7" \
--build-arg CANAL_COMPONENT_NAME="canal-adapter" \
--build-arg CANAL_DOWNLOAD_NAME="canal.adapter" \
-t wanghongxing/canal-adapter:v1.1.7-amd64 -t wanghongxing/canal-adapter:latest-amd64 -f Dockerfile . --push



docker    build --platform linux/arm64 \
--build-arg VCS_REF=`git rev-parse --short HEAD` \
--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
--build-arg CANAL_COMPONENT_VERSION="1.1.7" \
--build-arg CANAL_COMPONENT_NAME="canal-adapter" \
--build-arg CANAL_DOWNLOAD_NAME="canal.adapter" \
-t wanghongxing/canal-adapter:v1.1.7-arm64 -t wanghongxing/canal-adapter:latest-arm64 -f Dockerfile . --push