#这是我本地在苹果芯片笔记本上测试用的

 rm -rf canal-adapter
 cp -r ../canal/client-adapter/launcher/target/canal-adapter ./


docker    build --platform linux/arm64 \
--build-arg VCS_REF=`git rev-parse --short HEAD` \
--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
--build-arg CANAL_COMPONENT_VERSION="1.1.7" \
--build-arg CANAL_COMPONENT_NAME="canal-adapter" \
--build-arg CANAL_DOWNLOAD_NAME="canal.adapter" \
-t   wanghongxing/canal-adapter:latest-arm64 -f Dockerfile .