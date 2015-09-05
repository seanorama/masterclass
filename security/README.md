# Notes for our Hadoop Masterclasses

These notes are meant to accompany our Hadoop Security Masterclass which covers:
- Apache Falcon for data lifecycle
- Apache Atlas for metadata
- Apache Ranger for policy enforcement and access audits

## Requirements

Tested with:

    - Ambari 2.1.1
    - HDP 2.3.0
    - OpenJDK 8

More details on the deployment process at the end of this document.

Many manual steps are automated using scripts from my [Ambari Bootstrap scripts](https://seanorama/ambari-bootstrap). Clone them to your server with:
`cd ~; git clone https://seanorama/ambari-bootstrap`

## References

- Ambari
- Kerberos
- Ranger

## Labs

### Lab 1
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

## Deployment notes

### Deploy your host(s)

Requirements:

  - CentOS 7 (Should also work with CentOS & RedHat 6)

#### Notes for my Google Cloud environment

I was deploying a large number of hosts for each class. I did so with a messy set of bash & pdsh commands.

```
export lab_count=1
export lab_first=904
export lab_prefix=mc-lab
git clone https://github.com/seanorama/ambari-bootstrap /tmp/ambari-bootstrap
source "/tmp/ambari-bootstrap/providers/google/create-google-hosts.sh"
create=true "/tmp/ambari-bootstrap/providers/google/create-google-hosts.sh"
```

```
command="echo OK"; pdsh -w ${hosts_all} "${command}"
```

### Configure customer for the masterclass

This should be done on 1 node clusters

- For a single cluster simply execute this command from the cluster
curl -sSL https://raw.githubusercontent.com/seanorama/masterclass/master/security/setup.sh | bash

- If using PDSH:

    ```
read -r -d '' command <<EOF
curl -sSL https://raw.githubusercontent.com/seanorama/masterclass/master/security/setup.sh | bash
EOF
pdsh -w ${hosts_all} "${command}"
    ```
