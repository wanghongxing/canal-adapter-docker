# Canal Adapter Docker

clone from  [canal-docker](https://github.com/funnyzak/canal-docker)  of  [funnyzak](https://github.com/funnyzak)  

从  [funnyzak](https://github.com/funnyzak)   的  [canal-docker](https://github.com/funnyzak/canal-docker)  克隆过来后修改的。 

只制作Canal Adapter的镜像

本代码是以下docker镜像的源代码:

[Docker hub image: wanghongxing/canal-adapter](https://hub.docker.com/r/wanghongxing/canal-adapter)

**Docker Pull Command**: `docker pull wanghongxing/canal-adapter:v1.1.7`

 

## 原因

官方镜像对于oracle的全量同步有bug，我自己做了修复。

 

如下为patch

```java
Subject: [PATCH] 修复全量同步数据库时，目标数据库与源数据库不一致时获取数据库类型不一致的错误
---
Index: client-adapter/common/src/main/java/com/alibaba/otter/canal/client/adapter/support/Util.java
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
diff --git a/client-adapter/common/src/main/java/com/alibaba/otter/canal/client/adapter/support/Util.java b/client-adapter/common/src/main/java/com/alibaba/otter/canal/client/adapter/support/Util.java
--- a/client-adapter/common/src/main/java/com/alibaba/otter/canal/client/adapter/support/Util.java	(revision ea8949298fc74310990f24c864db218c7ccac312)
+++ b/client-adapter/common/src/main/java/com/alibaba/otter/canal/client/adapter/support/Util.java	(revision 6a94d89635a0d47e9b02ba2ca98565764727bfea)
@@ -38,7 +38,7 @@
     public static Object sqlRS(DataSource ds, String sql, Function<ResultSet, Object> fun) {
         try (Connection conn = ds.getConnection();
                 Statement stmt = conn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY)) {
-            stmt.setFetchSize(Integer.MIN_VALUE);
+            stmt.setFetchSize(0);
             try (ResultSet rs = stmt.executeQuery(sql)) {
                 return fun.apply(rs);
             }
@@ -52,7 +52,7 @@
         try (Connection conn = ds.getConnection()) {
             try (PreparedStatement pstmt = conn
                 .prepareStatement(sql, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY)) {
-                pstmt.setFetchSize(Integer.MIN_VALUE);
+                pstmt.setFetchSize(0);
                 if (values != null) {
                     for (int i = 0; i < values.size(); i++) {
                         pstmt.setObject(i + 1, values.get(i));
@@ -80,6 +80,8 @@
             consumer.accept(rs);
         } catch (SQLException e) {
             logger.error(e.getMessage(), e);
+            logger.error("sqlRs has error, sql: {} ", sql);
+
         }
     }
 
Index: client-adapter/rdb/src/main/java/com/alibaba/otter/canal/client/adapter/rdb/service/RdbEtlService.java
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
diff --git a/client-adapter/rdb/src/main/java/com/alibaba/otter/canal/client/adapter/rdb/service/RdbEtlService.java b/client-adapter/rdb/src/main/java/com/alibaba/otter/canal/client/adapter/rdb/service/RdbEtlService.java
--- a/client-adapter/rdb/src/main/java/com/alibaba/otter/canal/client/adapter/rdb/service/RdbEtlService.java	(revision ea8949298fc74310990f24c864db218c7ccac312)
+++ b/client-adapter/rdb/src/main/java/com/alibaba/otter/canal/client/adapter/rdb/service/RdbEtlService.java	(revision 6a94d89635a0d47e9b02ba2ca98565764727bfea)
@@ -59,9 +59,11 @@
             Map<String, Integer> columnType = new LinkedHashMap<>();
             DruidDataSource dataSource = (DruidDataSource) srcDS;
             String backtick = SyncUtil.getBacktickByDbType(dataSource.getDbType());
+            DruidDataSource targetDataSource = (DruidDataSource) targetDS;
+            String targetbacktick = SyncUtil.getBacktickByDbType(targetDataSource.getDbType());
 
             Util.sqlRS(targetDS,
-                "SELECT * FROM " + SyncUtil.getDbTableName(dbMapping, dataSource.getDbType()) + " LIMIT 1 ",
+                "SELECT * FROM " + SyncUtil.getDbTableName(dbMapping, targetDataSource.getDbType()) + SyncUtil.getLimitOneByDbType( targetDataSource.getDbType()),
                 rs -> {
                 try {
 
@@ -89,10 +91,10 @@
 
                     StringBuilder insertSql = new StringBuilder();
                     insertSql.append("INSERT INTO ")
-                        .append(SyncUtil.getDbTableName(dbMapping, dataSource.getDbType()))
+                        .append(SyncUtil.getDbTableName(dbMapping, targetDataSource.getDbType()))
                         .append(" (");
                     columnsMap
-                        .forEach((targetColumnName, srcColumnName) -> insertSql.append(backtick).append(targetColumnName).append(backtick).append(","));
+                        .forEach((targetColumnName, srcColumnName) -> insertSql.append(targetbacktick).append(targetColumnName).append(targetbacktick).append(","));
 
                     int len = insertSql.length();
                     insertSql.delete(len - 1, len).append(") VALUES (");
@@ -115,8 +117,8 @@
                             // 删除数据
                             Map<String, Object> pkVal = new LinkedHashMap<>();
                             StringBuilder deleteSql = new StringBuilder(
-                                "DELETE FROM " + SyncUtil.getDbTableName(dbMapping, dataSource.getDbType()) + " WHERE ");
-                            appendCondition(dbMapping, deleteSql, pkVal, rs, backtick);
+                                "DELETE FROM " + SyncUtil.getDbTableName(dbMapping, targetDataSource.getDbType()) + " WHERE ");
+                            appendCondition(dbMapping, deleteSql, pkVal, rs, targetbacktick);
                             try (PreparedStatement pstmt2 = connTarget.prepareStatement(deleteSql.toString())) {
                                 int k = 1;
                                 for (Object val : pkVal.values()) {
@@ -143,6 +145,7 @@
 
                                 i++;
                             }
+//                            logger.info("Delete target table, sql: {}", deleteSql.toString());
 
                             pstmt.execute();
                             if (logger.isTraceEnabled()) {
Index: client-adapter/rdb/src/main/java/com/alibaba/otter/canal/client/adapter/rdb/service/RdbSyncService.java
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
diff --git a/client-adapter/rdb/src/main/java/com/alibaba/otter/canal/client/adapter/rdb/service/RdbSyncService.java b/client-adapter/rdb/src/main/java/com/alibaba/otter/canal/client/adapter/rdb/service/RdbSyncService.java
--- a/client-adapter/rdb/src/main/java/com/alibaba/otter/canal/client/adapter/rdb/service/RdbSyncService.java	(revision ea8949298fc74310990f24c864db218c7ccac312)
+++ b/client-adapter/rdb/src/main/java/com/alibaba/otter/canal/client/adapter/rdb/service/RdbSyncService.java	(revision 6a94d89635a0d47e9b02ba2ca98565764727bfea)
@@ -362,6 +362,7 @@
 
         // 拼接主键
         appendCondition(dbMapping, updateSql, ctype, values, data, old);
+//        logger.info("Update target table, sql: {}", updateSql.toString());
         batchExecutor.execute(updateSql.toString(), values);
         if (logger.isTraceEnabled()) {
             logger.trace("Update target table, sql: {}", updateSql);
Index: client-adapter/rdb/src/main/java/com/alibaba/otter/canal/client/adapter/rdb/support/SyncUtil.java
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
diff --git a/client-adapter/rdb/src/main/java/com/alibaba/otter/canal/client/adapter/rdb/support/SyncUtil.java b/client-adapter/rdb/src/main/java/com/alibaba/otter/canal/client/adapter/rdb/support/SyncUtil.java
--- a/client-adapter/rdb/src/main/java/com/alibaba/otter/canal/client/adapter/rdb/support/SyncUtil.java	(revision ea8949298fc74310990f24c864db218c7ccac312)
+++ b/client-adapter/rdb/src/main/java/com/alibaba/otter/canal/client/adapter/rdb/support/SyncUtil.java	(revision 6a94d89635a0d47e9b02ba2ca98565764727bfea)
@@ -259,6 +259,8 @@
     public static String getDbTableName(MappingConfig.DbMapping dbMapping, String dbType) {
         String result = "";
         String backtick = getBacktickByDbType(dbType);
+//        logger.info("backtick:{}",backtick);
+
         if (StringUtils.isNotEmpty(dbMapping.getTargetDb())) {
             result += (backtick + dbMapping.getTargetDb() + backtick + ".");
         }
@@ -273,10 +275,12 @@
      * @return 反引号或空字符串
      */
     public static String getBacktickByDbType(String dbTypeName) {
+//        logger.info("dbTypeName:{}",dbTypeName);
         DbType dbType = DbType.of(dbTypeName);
         if (dbType == null) {
             dbType = DbType.other;
         }
+//        logger.info("DbType:{}",dbType);
 
         // 只有当dbType为MySQL/MariaDB或OceanBase时返回反引号
         switch (dbType) {
@@ -286,6 +290,26 @@
                 return "`";
             default:
                 return "";
+        }
+    }
+    public static String getLimitOneByDbType(String dbTypeName){
+//        logger.info("getLimit:{}",dbTypeName);
+        DbType dbType = DbType.of(dbTypeName);
+        if (dbType == null) {
+            dbType = DbType.other;
+        }
+//        logger.info("DbType:{}",dbType);
+
+        // 只有当dbType为MySQL/MariaDB或OceanBase时返回反引号
+        switch (dbType) {
+            case mysql:
+            case mariadb:
+            case oceanbase:
+                return " limit 1";
+            case oracle:
+                return " where rownum<2";
+            default:
+                return "";
         }
     }
 }

```



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

### 构建镜像

使用如下命令 build.sh

```bash
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
```

 

### 本地测试

因为我是苹果芯片的笔记本，使用如下命令 build-mac.sh：

注：如果你是intel芯片，就把arb64换成amd64

```bash
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
```



### 生成官方镜像

命令 build-offical.sh

```
#生成官方镜像

# build canal adapter
docker  buildx build --platform linux/arm64,linux/amd64 \
--build-arg VCS_REF=`git rev-parse --short HEAD` \
--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
--build-arg CANAL_COMPONENT_VERSION="1.1.7" \
--build-arg CANAL_COMPONENT_NAME="canal-adapter" \
--build-arg CANAL_DOWNLOAD_NAME="canal.adapter" \
-t wanghongxing/canal-adapter:v1.1.7 -t wanghongxing/canal-adapter:latest  -f Dockerfile.offical . --push



# build canal adapter
docker    build --platform linux/amd64 \
--build-arg VCS_REF=`git rev-parse --short HEAD` \
--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
--build-arg CANAL_COMPONENT_VERSION="1.1.7" \
--build-arg CANAL_COMPONENT_NAME="canal-adapter" \
--build-arg CANAL_DOWNLOAD_NAME="canal.adapter" \
-t wanghongxing/canal-adapter:v1.1.7-amd64 -t wanghongxing/canal-adapter:latest-amd64  -f Dockerfile.offical . --push



docker    build --platform linux/arm64 \
--build-arg VCS_REF=`git rev-parse --short HEAD` \
--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
--build-arg CANAL_COMPONENT_VERSION="1.1.7" \
--build-arg CANAL_COMPONENT_NAME="canal-adapter" \
--build-arg CANAL_DOWNLOAD_NAME="canal.adapter" \
-t wanghongxing/canal-adapter:v1.1.7-arm64 -t wanghongxing/canal-adapter:latest-arm64  -f Dockerfile.offical . --push
```

