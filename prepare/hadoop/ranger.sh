#!/usr/bin/env bash

## variables you may change
ambari_user=admin
ambari_pass=admin
ambari_host=localhost
ambari_api=http://${ambari_host}:8080/api/v1
ambari_curl="curl -ksu ${ambari_user}:${ambari_pass} ${ambari_api}"

## don't touch the rest

ambari_cluster=$(${ambari_curl}/clusters \
    | python -c 'import sys,json; \
          print json.load(sys.stdin)["items"][0]["Clusters"]["cluster_name"]')
configssh="/var/lib/ambari-server/resources/scripts/configs.sh \
  -u ${ambari_user} -p ${ambari_pass}"
config_set="${configssh} set ${ambari_host} ${ambari_cluster}"
config_get="${configssh} get ${ambari_host} ${ambari_cluster}"

sudo yum -y install mysql-connector-java
sudo ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar

## Ranger KMS
${config_set} kms-properties db_root_user rangerroot
${config_set} ranger-kms-audit xasecure.audit.destination.hdfs.dir "hdfs://$(hostname -f):8020/ranger/audit"
${config_set} ranger-kms-security ranger.plugin.kms.policy.rest.url http://localhost:6080

## Ranger ugsync
${config_set} ranger-admin-site ranger.externalurl http://localhost:6080
${config_set} ranger-ugsync-site ranger.usersync.policymanager.baseURL http://localhost:6080

${config_set} ranger-ugsync-site ranger.usersync.ldap.ldapbindpassword "BadPass#1"
${config_set} ranger-ugsync-site ranger.usersync.ldap.searchBase "dc=hortonworks,dc=com"
${config_set} ranger-ugsync-site ranger.usersync.source.impl.class ldap
${config_set} ranger-ugsync-site ranger.usersync.ldap.binddn "CN=Ranger Admin,OU=sandbox,OU=hdp,DC=hortonworks,DC=com"
${config_set} ranger-ugsync-site ranger.usersync.ldap.url "ldaps://activedirectory.hortonworks.com"
${config_set} ranger-ugsync-site ranger.usersync.ldap.user.nameattribute "sAMAccountName"
${config_set} ranger-ugsync-site ranger.usersync.ldap.user.searchbase "dc=hortonworks,dc=com"
${config_set} ranger-ugsync-site ranger.usersync.group.searchbase "dc=hortonworks,dc=com"
${config_set} ranger-ugsync-site ranger.usersync.ldap.user.searchfilter "(objectcategory=person)"


## testing ad
ranger.usersync.ldap.user.groupnameattribute "memberof, ismemberof, msSFU30PosixMemberOf"
${config_set} ranger-ugsync-site ranger.usersync.group.memberattributename member
${config_set} ranger-ugsync-site ranger.usersync.group.nameattribute cn
${config_set} ranger-ugsync-site ranger.usersync.group.objectclass groupofnames

## Ranger HDFS Plugin
${config_set} ranger-hdfs-audit xasecure.audit.destination.hdfs true
${config_set} ranger-hdfs-audit xasecure.audit.destination.db true
${config_set} ranger-hdfs-audit xasecure.audit.destination.hdfs.dir "hdfs://$(hostname -f):8020/ranger/audit"
${config_set} ranger-hdfs-audit xasecure.audit.is.enabled true
${config_set} ranger-hdfs-audit xasecure.audit.provider.summary.enabled true
${config_set} hdfs-site dfs.namenode.inode.attributes.provider.class org.apache.ranger.authorization.hadoop.RangerHdfsAuthorizer

${config_set} ranger-hdfs-plugin-properties ranger-hdfs-plugin-enabled yes
${config_set} ranger-hdfs-plugin-properties REPOSITORY_CONFIG_PASSWORD "BadPass#1"
${config_set} ranger-hdfs-plugin-properties REPOSITORY_CONFIG_USERNAME "rangeradmin@HORTONWORKS.COM"
${config_set} ranger-hdfs-plugin-properties common.name.for.certificate " "

## Workaround for a bug in HDP 2.3 TP7
hadoop_env=$(${config_get} hadoop-env | awk '/^"content" : "/' \
  | sed -e 's/^"content" : "//' \
  -e 's/",$/\\nexport HADOOP_CLASSPATH=${HADOOP_CLASSPATH}:${JAVA_JDBC_LIBS}:\\n\\n/')
${config_set} hadoop-env content "${hadoop_env}"

## (optional) For demoing only to get hdfs audits quickly
${config_set} ranger-hdfs-audit xasecure.audit.hdfs.async.max.flush.interval.ms 30000
${config_set} ranger-hdfs-audit xasecure.audit.hdfs.config.destination.flush.interval.seconds 60
${config_set} ranger-hdfs-audit xasecure.audit.hdfs.config.destination.open.retry.interval.seconds 60
${config_set} ranger-hdfs-audit xasecure.audit.hdfs.config.destination.rollover.interval.seconds 30
${config_set} ranger-hdfs-audit xasecure.audit.hdfs.config.local.buffer.flush.interval.seconds 60
${config_set} ranger-hdfs-audit xasecure.audit.hdfs.config.local.buffer.rollover.interval.seconds 60

## Ranger Hive Plugin

${config_set} hive-env hive_security_authorization Ranger

${config_set} hive-site hive.security.authorization.enabled true
${config_set} hive-site hive.server2.enable.doAs false
${config_set} hive-site hive.server2.enable.impersonation true

${config_set} hiveserver2-site hive.security.authorization.enabled true
${config_set} hiveserver2-site hive.security.authorization.manager org.apache.ranger.authorization.hive.authorizer.RangerHiveAuthorizerFactory

${config_set} ranger-hive-audit xasecure.audit.destination.db true
${config_set} ranger-hive-audit xasecure.audit.destination.hdfs true
${config_set} ranger-hive-audit xasecure.audit.provider.summary.enabled true
${config_set} ranger-hive-audit xasecure.audit.is.enabled true
${config_set} ranger-hive-audit xasecure.audit.provider.summary.enabled true
${config_set} ranger-hive-audit xasecure.audit.destination.hdfs.dir "hdfs://$(hostname -f):8020/ranger/audit"

${config_set} ranger-hive-plugin-properties ranger-hive-plugin-enabled yes
${config_set} ranger-hive-plugin-properties REPOSITORY_CONFIG_PASSWORD "BadPass#1"
${config_set} ranger-hive-plugin-properties REPOSITORY_CONFIG_USERNAME "rangeradmin@HORTONWORKS.COM"
${config_set} ranger-hive-plugin-properties common.name.for.certificate " "

${config_set} core-site hadoop.proxyuser.ambari.groups "*"
${config_set} core-site hadoop.proxyuser.ambari.hosts "*"
