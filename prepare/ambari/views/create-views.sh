#!/usr/bin/env bash

## install Amabari Views with the JSON files in this directory
##  this only works on non-kerberized clusters where all servers are on the same node

## fix for ambari views
cluster=$(curl -s -u admin:admin http://localhost:8080/api/v1/clusters | jq -r '.items[].Clusters.cluster_name')
# https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/Superusers.html
/var/lib/ambari-server/resources/scripts/configs.sh set localhost ${cluster} core-site hadoop.proxyuser.root.groups "*"
/var/lib/ambari-server/resources/scripts/configs.sh set localhost ${cluster} core-site hadoop.proxyuser.root.hosts "*"

## install views
views="hive files pig"
for view in ${views}; do
  sed -e "s/localhost/$(hostname -f)/" ${view}.json > /tmp/ambari-view-${view}.json
    curl -v -X POST -u admin:admin \
      -H X-Requested-By:sean \
      http://localhost:8080/api/v1/views/${view^^}/versions/1.0.0/instances/${view~} \
      -d @/tmp/ambari-view-${view}.json
done
