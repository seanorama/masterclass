# Security masterclass notes & script

## Deploy nodes

This tutorial requires RedHat/CentOS 6 or 7.

### Google Cloud

```
cd ~/src/masterclass/prepare/google

export lab_first=10
export lab_count=10
export lab_prefix=mc-lab

create=true ./create-lab.sh

source ./create-lab.sh
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
/opt/ambari-bootstrap/extras/deploy/deploy-hdp.sh
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

```


## Notes or fixing issues

#### Update ambari-bootstrap
```
export PDSH_SSH_ARGS_APPEND="-l student -i ${HOME}/.ssh/student.pri.key -o ConnectTimeout=5 -o CheckHostIP=no -o StrictHostKeyChecking=no -o RequestTTY=force"

command="cd /opt/ambari-bootstrap; git pull"
pdsh -w ${hosts_all} "${command}"
```

#### Check hosts