#!/usr/bin/env bash
set -o xtrace

export HOME=${HOME:-/root}
export TERM=xterm

: ${install_ambari_server:=true}
: ${ambari_pass:="BadPass#1"}
ambari_password="${ambari_pass}"
: ${host_count:=skip}
: ${ambari_services:="HDFS MAPREDUCE2 PIG HIVE YARN ZOOKEEPER TEZ SLIDER"}
cluster_name=${stack:-mycluster}

export install_ambari_server ambari_pass host_count ambari_services
export ambari_password cluster_name

#export ambari_repo=http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.4.1.0/ambari.repo
#export ambari_repo=http://public-repo-1.hortonworks.com/HDP-LABS/Projects/Erie-Preview/ambari/2.4.0.0-2/centos6/ambari.repo
export recommendation_strategy="ALWAYS_APPLY_DONT_OVERRIDE_CUSTOM_VALUES"

cd

yum makecache
yum -y -q install git

git clone http://github.com/seanorama/ambari-bootstrap
cd ambari-bootstrap
./ambari-bootstrap.sh

## Ambari Server specific tasks
if [ "${install_ambari_server}" = "true" ]; then
    bash -c "nohup ambari-server restart" || true

    sleep 60

    ambari_pass=admin source ~/ambari-bootstrap/extras/ambari_functions.sh
    ambari_change_pass admin admin ${ambari_pass}

#  alias curl="curl -L -H X-Requested-By:blah -u admin:${ambari_pass}"
#cat > /tmp/repo.json <<-'EOF'
#{
  #"Repositories": {
    #"base_url": "http://public-repo-1.hortonworks.com/HDP-UTILS-1.1.0.21/repos/centos6",
    #"verify_base_url": true
  #}
#}
#EOF
  #url="http://localhost:8080/api/v1/stacks/HDP/versions/2.5/operating_systems/redhat6/repositories/HDP-UTILS-1.1.0.21"
  #curl -X PUT "${url}" -d @/tmp/repo.json
  #curl "${url}"
  #rm -f /tmp/repo.json

  ## register HDP repo
#cat > /tmp/repo.json <<-'EOF'
#{
  #"Repositories": {
    #"base_url": "http://public-repo-1.hortonworks.com/HDP-LABS/Projects/Erie-Preview/2.5.0.0-2/centos6",
    #"verify_base_url": true
  #}
#}
#EOF
  #url="http://localhost:8080/api/v1/stacks/HDP/versions/2.5/operating_systems/redhat6/repositories/HDP-2.5"
  #curl -X PUT "${url}" -d @/tmp/repo.json
  #curl "${url}"
  #rm -f /tmp/repo.json
  #unalias curl

    if [ "${deploy}" = "true" ]; then

        cd ~/ambari-bootstrap/deploy

cat << EOF > configuration-custom.json
{
  "configurations" : {
    "core-site": {
        "hadoop.proxyuser.HTTP.groups" : "users,hadoop-users",
        "hadoop.proxyuser.HTTP.hosts" : "*",
        "hadoop.proxyuser.hbase.groups" : "users,hadoop-users",
        "hadoop.proxyuser.hbase.hosts" : "*",
        "hadoop.proxyuser.hcat.groups" : "users,hadoop-users",
        "hadoop.proxyuser.hcat.hosts" : "*",
        "hadoop.proxyuser.hive.groups" : "users,hadoop-users",
        "hadoop.proxyuser.hive.hosts" : "*",
        "hadoop.proxyuser.knox.groups" : "users,hadoop-users",
        "hadoop.proxyuser.knox.hosts" : "*",
        "hadoop.proxyuser.oozie.groups" : "users",
        "hadoop.proxyuser.oozie.hosts" : "*",
        "hadoop.proxyuser.root.groups" : "users,hadoop-users",
        "hadoop.proxyuser.root.hosts" : "*",
        "fs.trash.interval": "4320"
    },
    "hive-interactive-env": {
        "enable_hive_interactive": "true",
        "llap_queue_capacity": "75"
    },
    "yarn-site": {
        "yarn.acl.enable" : "true"
    },
    "hdfs-site": {
      "dfs.namenode.safemode.threshold-pct": "0.99"
    },
    "hive-site": {
        "hive.exec.compress.output": "true",
        "hive.merge.mapfiles": "true",
        "hive.server2.tez.initialize.default.sessions": "true"
    },
    "mapred-site": {
        "mapreduce.job.reduce.slowstart.completedmaps": "0.7",
        "mapreduce.map.output.compress": "true",
        "mapreduce.output.fileoutputformat.compress": "true"
    }
  }
}
EOF
        ./deploy-recommended-cluster.bash

        source ~/ambari-bootstrap/extras/ambari_functions.sh
        ambari_configs
        ambari_wait_request_complete 1

        cd ~
        sleep 10

        useradd -G users admin
        echo "${ambari_pass}" | passwd admin --stdin
        sudo -u hdfs bash -c "
            hadoop fs -mkdir /user/admin;
            hadoop fs -chown admin /user/admin;
            hdfs dfsadmin -refreshUserToGroupsMappings"
    fi
fi


