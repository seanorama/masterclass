#!/usr/bin/env bash

## install Amabari Views with the JSON files in this directory
##  this only works on non-kerberized clusters where all servers are on the same node

## install views
views="hive files pig"
for view in ${views}; do
  json=$(sed -e "s/localhost/$(hostname -f)/" ${view}.json)
  echo ${json} | jq '.'
done

echo ${json} | \
  curl -v -X POST -u admin:admin \
    -H X-Requested-By:sean \
    http://localhost:8080/api/v1/views/FILES/versions/1.0.0/instances/Files
    --data -
