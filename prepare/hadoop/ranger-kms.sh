#!/usr/bin/env bash

## variables you may change
ambari_user=admin
ambari_pass=BadPass#1
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

#sudo yum -y install mysql-connector-java
#sudo ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar

sudo ln -s /etc/hadoop/conf/core-site.xml /etc/ranger/kms/conf/core-site.xml

sudo keytool -import -trustcacerts -alias root -noprompt -storepass changeit  -file /etc/pki/ca-trust/source/anchors/activedirectory.pem -keystore /usr/hdp/current/ranger-kms/conf/ranger-plugin-keystore.jks
## Ranger KMS
#${config_set} kms-properties db_root_user rangerroot
#${config_set} ranger-kms-security ranger.plugin.kms.policy.rest.url http://localhost:6080

${config_set} kms-properties REPOSITORY_CONFIG_PASSWORD "BadPass#1"
${config_set} kms-properties REPOSITORY_CONFIG_USERNAME "rangeradmin@HORTONWORKS.COM"
${config_set} kms-properties common.name.for.certificate " "

${config_set} core-site hadoop.security.key.provider.path "kms://http@$(hostname -f):9292/kms"
${config_set} hdfs-site dfs.encryption.key.provider.uri "kms://http@$(hostname -f):9292/kms"
#${config_set} kms-site hadoop.kms.authentication.type kerberos
#${config_set} kms-site hadoop.kms.authentication.kerberos.keytab /etc/security/keytabs/spnego.service.keytab
${config_set} kms-site hadoop.kms.authentication.kerberos.principal "HTTP/$(hostname -f)@HORTONWORKS.COM"
${config_set} kms-site hadoop.kms.key.provider.uri "kms://http@$(hostname -f):9292/kms"




${config_set} kms-site hadoop.kms.proxyuser.rangeradmin.users "rangeradmin, admin"
${config_set} kms-site hadoop.kms.proxyuser.rangeradmin.hosts "*"
${config_set} kms-site hadoop.kms.proxyuser.rangeradmin.groups "users, hadoop-users"

${config_set} ranger-kms-audit xasecure.audit.destination.db true
${config_set} ranger-kms-audit xasecure.audit.provider.summary.enabled true
${config_set} ranger-kms-audit xasecure.audit.is.enabled true
${config_set} ranger-kms-audit xasecure.audit.destination.hdfs.dir "hdfs://$(hostname -f):8020/ranger/audit"

