# Security masterclass notes & script

## Deploy nodes

This tutorial requires RedHat/CentOS 6 or 7.

### Google Cloud

```
### update these!
export lab_count=10 # number of clusters to create
export lab_prefix=mc-lab # prefix in hostname
export lab_first=10 # number to start on for the hostname

cd ~/src/masterclass/prepare/google
source ./create-lab.sh
create=true ./create-lab.sh
```

## Prepare nodes

### On all providers

```
## TODO: extract from google compute things that are generic
```

### Google Compute specific

```
read -r -d '' command <<EOF
curl -sSL https://raw.githubusercontent.com/seanorama/ambari-bootstrap/master/extras/deploy/install-ambari-bootstrap.sh | bash
sudo /opt/ambari-bootstrap/extras/deploy/prep-hosts.sh
sudo /opt/ambari-bootstrap/providers/growroot.sh
sudo reboot
EOF
pdsh -w ${hosts_all} "${command}"
```

### Check if hosts are back up
```
command="uptime"
pdsh -w ${hosts_all} "${command}"
```

### Deploy HDP

```
read -r -d '' command <<EOF
export ambari_services="KNOX YARN ZOOKEEPER TEZ PIG SLIDER MAPREDUCE2 HIVE HDFS HBASE"
export ambari_services="YARN ZOOKEEPER TEZ OOZIE FLUME PIG SLIDER MAPREDUCE2 HIVE HDFS FALCON ATLAS SQOOP"
/opt/ambari-bootstrap/extras/deploy/deploy-hdp.sh
EOF
pdsh -w ${hosts_all} "${command}"
```

```
read -r -d '' command <<EOF
sudo chkconfig mysqld on; sudo service mysqld start

/opt/ambari-bootstrap/extras/add-trusted-ca.sh
/opt/ambari-bootstrap/extras/samples/sample-data.sh
/opt/ambari-bootstrap/extras/configs/proxyusers.sh
source ~/ambari-bootstrap/extras/ambari_functions.sh; ambari-change-pass admin admin BadPass#1
echo export ambari_pass=BadPass#1 > ~/.ambari.conf; chmod 600 ~/.ambari.conf
EOF

pdsh -w ${hosts_all} "${command}"
```

### Set Ambari Password
```
read -r -d '' command <<EOF
source ~/ambari-bootstrap/extras/ambari_functions.sh; ambari-change-pass admin admin BadPass#1
echo export ambari_pass=BadPass#1 > ~/.ambari.conf; chmod 600 ~/.ambari.conf
EOF
pdsh -w ${hosts_all} "${command}"
```

## For users to do

#### Ambari LDAP

## After kerberos is implemented

#### Integrate OS with Active Directory
```
~/ambari-bootstrap/extras/sssd-kerberos-ad.sh
```

#### Ambari non-root
```
~/ambari-bootstrap/extras/ambari-non-root.sh
sudo service ambari-server stop
sudo service ambari-server start
```

#### Ambari Kerberos JAAS
```
~/ambari-bootstrap/extras/ambari-kerberos-jaas.sh
sudo service ambari-server restart
```


#### Ambari: Recreate views
```
~/ambari-bootstrap/extras/ambari-views/create-views.sh
```

## after ranger is implemented
```
sudo service mysqld start
cat << EOF | sudo mysql
GRANT ALL PRIVILEGES ON *.* to 'root'@'$(hostname -f)' WITH GRANT OPTION;
SET PASSWORD FOR 'root'@'$(hostname -f)' = PASSWORD('BadPass#1');
FLUSH PRIVILEGES;
exit
EOF
```


## Notes or fixing issues

#### Update ambari-bootstrap
```
export PDSH_SSH_ARGS_APPEND="-l student -i ${HOME}/.ssh/student.pri.key -o ConnectTimeout=5 -o CheckHostIP=no -o StrictHostKeyChecking=no -o RequestTTY=force"

command="cd /opt/ambari-bootstrap; git pull"
pdsh -w ${hosts_all} "${command}"
```

#### Check hosts
```
command="uptime"
pdsh -w ${hosts_all} "${command}"
```

```
ip=$(curl -4 icanhazip.com)
gcloud compute --project "siq-haas" firewall-rules create "source-$(echo ${ip} | tr '.' '-')"   --allow tcp,udp --network "hdp-partner-workshop" --source-ranges "${ip}/32"
```