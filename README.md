# Canal Docker

clone from  [canal-docker](https://github.com/funnyzak/canal-docker)  of  [funnyzak](https://github.com/funnyzak)  

 Docker images for [canal](https://github.com/alibaba/canal). The images is based on Official [canal](https://github.com/alibaba/canal) repo.

 **Sync with the latest version of canal.**

This repository contains the following images:

- [canal-adapter](https://github.com/alibaba/canal/tree/master/client-adapter)

## Docker Images

### Canal Adapter



[Docker hub image: wanghongxing/canal-adapter](https://hub.docker.com/r/wanghongxing/canal-adapter)

**Docker Pull Command**: `docker pull wanghongxing/canal-adapter:v1.1.7`

 

## Usage

### Compose

```yaml
version: '3.7'
services:
  canal-server:
    image: canal/canal-server:v1.1.7
    container_name: canal-server
    restart: on-failure
    environment:
      - canal.auto.scan=true
      - canal.destinations=example_destination
      - canal.instance.mysql.slaveId=166
      - canal.instance.master.address=mysql:3306
      - canal.instance.dbUsername=root
      - canal.instance.dbPassword=examplepwd123456
      - canal.instance.connectionCharset=UTF-8
      - canal.instance.tsdb.enable=true
      - canal.instance.gtidon=false
      - canal.instance.parser.parallelThreadSize=16
      - canal.instance.filter.regex=db_name.table_1,db_name.table_2
    volumes:
      - ./canal/canal-server/conf:/opt/canal/canal-server/conf
      - ./canal/canal-server/logs:/opt/canal/canal-server/logs
    networks:
      - my-network
    depends_on:
      - mysql
  canal-adapter:
    image: wanghongxing/canal-adapter:v1.1.7
    container_name: canal-adapter
    restart: on-failure
    volumes:
      - ./canal/canal-adapter/conf:/opt/canal/canal-adapter/conf
      - ./canal/canal-adapter/logs:/opt/canal/canal-adapter/logs
    networks:
      - my-network
    depends_on:
      - canal-server
      - mysql
      - other storage...
  canal-admin:
    image: funnyzak/canal-admin:latest
    container_name: canal-admin
    restart: on-failure
    volumes:
      - ./canal/canal-admin/conf:/opt/canal/canal-admin/conf
      - ./canal/canal-admin/logs:/opt/canal/canal-admin/logs
    networks:
      - my-network
    depends_on:
      - canal-server
networks:
  default:
    external:
      name: my-network
```

 

## Docker Build

For building docker images, you can use the following command:

```bash
 

# build canal adapter
docker build \
--build-arg VCS_REF=`git rev-parse --short HEAD` \
--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
--build-arg CANAL_COMPONENT_VERSION="1.1.6" \
--build-arg CANAL_COMPONENT_NAME="canal-adapter" \
--build-arg CANAL_DOWNLOAD_NAME="canal.adapter" \
-t funnyzak/canal-adapter .

 
```

 https://github.com/funnyzak)
