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


## Fixes for Files & Hive views

${config_set} core-site hadoop.proxyuser.ambari.users "admin"
${config_set} core-site hadoop.proxyuser.ambari.groups "users, hadoop-users, sales, legal, marketing, hr"
${config_set} core-site hadoop.proxyuser.ambari.hosts "localhost, $(hostname -f)"

${config_set} core-site hadoop.proxyuser.hbase.groups "users, hadoop-users"
${config_set} core-site hadoop.proxyuser.hcat.groups "users, hadoop-users"
${config_set} core-site hadoop.proxyuser.hive.groups "users, hadoop-users"
${config_set} core-site hadoop.proxyuser.knox.groups "users, hadoop-users"
${config_set} core-site hadoop.proxyuser.HTTP.groups "users, hadoop-users"

#${config_set} hive-site hive.server2.enable.impersonation true
${config_set} hive-site hive.server2.enable.doAs false
${config_set} hive-site hive.security.authorization.enabled true
${config_set} hiveserver2-site hive.security.authorization.enabled true
