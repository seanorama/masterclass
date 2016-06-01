#!/usr/bin/env bash
set -o xtrace

export HOME=${HOME:-/root}
cd

export TERM=xterm
export ambari_pass=${ambari_pass:-BadPass#1}
#export ambari_version=2.2.2.0

yum makecache
yum -y -q install git patch

sed -i -e 's/\(PermitRootLogin\).*/\1 yes/g' /etc/ssh/sshd_config
service sshd reload

cat <<'EOF' > /root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDB/hBQfzF91SExZ4MglU7eX26RfIEsz5aCGzzbaGeQG7Jch5XIWHE192A/5jRUZy2eU5sFMsYS32LEqKSVJn5N/5P7yE2QvcTUosM7wHWQW4JrImL0PTJTPXRc/QvkGPka3LvBCL6PlVENyGGo+C3D+dgSloaBeZ9URk0I+Yc/VsihQoMdkVOYIKAGxZlG/JBEBBjCZ5ng4WlzdfcsKgtUGbr6nOn3mqK8/Pkv8CeWguEYaibj5Os6ydmHVZ30w0tLD6Gu7UH14M3M3LnNlCndSLG4bRzUP6OxGEFWlG8GPJnv3Z3h3obqK3jIAsx8GHR9ExR8YdNlvkigbQg8xDGJ Generated-by-Nova
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAwK5PtfU60ZWtLCRmBODs1KX1Y7sup1acaO98P/uE3QFZauvFFqo+z2R4w/WT6i4zHpH/bHP6tGPeTjph6eX1jJ+l030e9CbFD2Dw5/d3oj/snP7QCl/nyzqozYJ2lxY3j+/5wXDXHrBxM5MKfONY1MUQmTr1naVhu+ud5Ar1vtIH4zFm3Z1/akLZUWaYJVpDVpPDyJo4gEC9z8of4SFKHntNnPHsFoyXptb5yiGAwljVdRc0P4cMsSqxHkU6OLkuKY9Uxu6btB9fE4FerPj8jleahjPVaViGm2yRE2UJd0dOzerJ7W0dCwiOmJbsDMVxuiPg/tf785AqlL3t/9PW5Q== qe-jenkins@10.10.11.69
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0oYPLnbHdwPBSGebDXncxXdPvxKG0v4n9B2eFTk1qlkrp2nlRvghAfb69f68unDr/2ywoY/7IsPD4ITubponZlgwxZ6xOiwNu3WVHsU3Ot9PdC+YdCp+BeTJVBCbRmW+JGK44E00vYn6Yc/Mfqwnv/cbZGDztTXuNJWO9S2ETFQY8hl1IUL/oUBYtDdsoKUMRNKeceDKzYIc6yVJ6UgqmBTWCl2MYBd29wAFlUkr1Ynv3h1ZxwVv0ZzlUeJVhKc8o1/QLkWMzL7kCGQCy6r2lZLXKFPBBBHZVm0x0IDiessB7hjI/8UMjHsug/MkvTrw995wLQHnz6MDihuBfCUcd jenkins@10.10.10.66-hortworksre
EOF

useradd hrt_qa
export AWS_DEFAULT_REGION=${region}
echo 
# put ip of all nodes /tmp/all_internal_nodes


git clone -b feature/amazon-linux http://github.com/seanorama/ambari-bootstrap
cd ambari-bootstrap

# export install_ambari_server=true
./ambari-bootstrap.sh
yum -y -q install smartsense-hst

## monkeypatching smartsense for Python=>2.7.9
URL="https://gist.githubusercontent.com/seanorama/bbe936cff511d8e5b98f1c8b6c155f55/raw/5446e0747e0a6e99b49c881e23a70748aec97b19/security.py.diff"
curl -sSL "${URL}" | patch -b /usr/hdp/share/hst/hst-agent/lib/hst_agent/security.py

## monkeypatching ambari-agent for Amazon Linux 2016.03
URL="https://gist.githubusercontent.com/seanorama/fdd64d9648ad3d7897d5115e02f532bd/raw/00b11e7cb87c5d9e5662eb3634ce41f9889a5fcb/BUG-57329.diff"
curl -sSL -O "${URL}"
for a in agent server; do
    patch -b \
        /usr/lib/ambari-${a}/lib/ambari_commons/resources/os_family.json \
        BUG-57329.diff || true
done
rm BUG-57329.diff

bash -c "nohup ambari-agent restart" || true

## Ambari Server specific tasks
if [ "${install_ambari_server}" = "true" ]; then
    bash -c "nohup ambari-server restart" || true

    sleep 60

    ambari_pass=admin source ~/ambari-bootstrap/extras/ambari_functions.sh
    ambari-change-pass admin admin ${ambari_pass}

    if [ "${deploy}" = "true" ]; then

        export ambari_password="${ambari_pass}"
        export cluster_name=${stack:-mycluster}
        export host_count=${host_count:-skip}
        export ambari_services="${ambari_services:-HDFS MAPREDUCE2 PIG HIVE YARN ZOOKEEPER SPARK AMBARI_METRICS SQOOP TEZ SMARTSENSE}"

        cd ~/ambari-bootstrap/deploy

cat << EOF > configuration-custom.json
{
  "configurations" : {
    "core-site": {
        "fs.trash.interval" : "4320"
    },
    "hdfs-site": {
        "dfs.namenode.safemode.threshold-pct" : "0.99",
        "dfs.datanode.du.reserved" : "4294967296"
    },
    "hive-site" : {
        "hive.exec.compress.intermediate" : "true",
        "hive.exec.compress.output" : "true",
        "hive.merge.mapfiles" : "false",
        "hive.server2.tez.initialize.default.sessions" : "true"
    },
    "yarn-site": {
        "yarn.acl.enable" : "true"
    },
    "mapred-site": {
        "mapreduce.job.reduce.slowstart.completedmaps" : "0.7",
        "mapreduce.map.output.compress" : "true",
        "mapreduce.output.fileoutputformat.compress" : "true"
    },
    "hst-server-conf": {
          "customer.account.name" : "Internal: AWS Marketplace",
          "customer.smartsense.id" : "A-99900000-C-00000001",
          "customer.notification.email" : "sroberts@hortonworks.com"
    },
    "hdfs-site" : {
        "dfs.namenode.name.dir" : "/grid/00/hadoop/hdfs/nn,/grid/01/hadoop/hdfs/nn",
        "dfs.journalnode.edits.dir" : "/grid/00/hadoop/hdfs/jn,/grid/01/hadoop/hdfs/jn",
        "dfs.datanode.data.dir" : "/grid/00/hadoop/hdfs/dn,/grid/01/hadoop/hdfs/dn",
        "dfs.datanode.failed.volumes.tolerated" : "1"
    }
  }
}
EOF
        ./deploy-recommended-cluster.bash

        source ~/ambari-bootstrap/extras/ambari_functions.sh
        ambari-configs
        ambari_wait_request_complete 1

        cd ~
        sleep 10

        bash -c "nohup ambari-server restart" || true

    fi
fi

