#!/usr/bin/env bash

UID_MIN=$(awk '$1=="UID_MIN" {print $2}' /etc/login.defs)
users="${users:-$(getent passwd|awk -v UID_MIN="${UID_MIN}" -F: '$3>=UID_MIN{print $1}')}"

dfs_cmd="sudo sudo -u hdfs hadoop fs"
for user in ${users}; do
    if ! ${dfs_cmd} -stat /user/${user}; then
      ${dfs_cmd} -mkdir -p "/user/${user}"
      ${dfs_cmd} -chown "${user}" "/user/${user}" &
    fi
done


