### this is a work in progress. Probably should have put it on a different branch... too late


# Hadoop Security Masterclass

Notes and rough agenda

## Logistics

### Lab environments

Each user environment has 2 servers:

1. `p-labNN-hdp`:  CentOS with Ambari 2.1 & HDP 2.3
	- Private name:  
2. `p-labNN-ipa`: CentOS with FreeIPA (Kerberos/LDAP)

Details:

* SSH
	* User: student
	* Pass:
	* Key:
	* Web SSH client: https://hostname:4200/
* HDP
	* Ambari: p-labNN-hdp:8080
		* Credentials: admin/admin
	* Knox:   p-labNN-hdp:8443
* FreeIPA (Kerberos & LDAP)
	* Realm: HORTONWORKS.COM
	* Domain: hortonworks.com
	* User: admin
	* Pass: 
	* LDAP: p-labNN-ipa:389
	* Web UI: https://p-labNN-ipa/ipa/ui/
		* This requires an update to your laptops host files. From 'p-lanNN-ipa', execute:
			* `echo "$(curl -s icanhazip.com) $(hostname -f) $(hostname -s)"`


--------

## Getting to know the environment

Ambari

* http://p-labXX:8080

SSH

* OSX & Linux: ssh student@
* Windows: putty, openssh, ...
* Web: http://hostname:4200

Linux

* Get your internal hostname: `hostname -f`
* Get your public ip: `curl icanhazip.com`
* Run as root: `sudo ls /usr/hdp/current`
* Become another user: `sudo su - hdfs`
* Check if a user comes from local or ldap:

	```shell
## normal user:
$ id student
uid=1002(student) gid=1002(student) groups=1002(student),4(adm),39(video),40(dip)

## ldap & user:
$ id admin
uid=1943800000(admin) gid=1943800000(admins) groups=1943800000(admins)
	```

IPA *(Management of LDAP & Kerberos)*

* Authenticate as KDC admin: `kinit admin`
* Add group: `ipa group-add mygroup --desc mygroup`
* Add user: `ipa user-add myuser --first=first --last=last`
* Set their password: `ipa passwd myuser`
* *(optional) Use the FreeIPA Web UI. See logistics details above.*
* If admin user gets locked out: `LDAPTLS_CACERT=/etc/ipa/ca.crt ldappasswd -h localhost -ZZ -D 'cn=directory manager' -W -S uid=admin,cn=users,cn=accounts,dc=hortonworks,dc=com`

Kerberos

* Get a ticket: `kinit`
* Get a ticket for another "principal": `kinit admin`
* List tickets: `klist`
* Destroy tickets: `kdestroy` 

Hadoop

* Hadoop Commands:
	* `hadoop fs -mkdir /user/myuser`
	* `hadoop fs -chown myuser /user/myuser`
	* Put a local file into HDFS `hadoop fs -put /usr/hdp/current/hadoop-client/conf/hdfs-site.xml /user/myuser/`

## Lab 01: Linux, IPA, Kerberos & Hadoop basics

1. SSH to both of your lab environments
1. Note the full hostname of each server
1. Create a new user in LDAP (with your name)
1. Create their home directory in HDFS
1. Become them using sudo & su
1. Get a kerberos ticket & list it's details

--------

## Hadoop security: out the box

Hadoop relies on system users. For example:

	```shell
$ whoami
student
$ hadoop fs -mkdir /tmp/student-dir
$ hadoop fs -ls -d /tmp/student-dir
drwxr-xr-x   - student hdfs          0 2015-07-14 17:32 /tmp/student-dir
	```

It appears secure:

	```
	
	```

#### Superusers

* Grants a user rights to submit jobs as other users
* Configured at `HDFS / core-site`
	* `hadoop.proxyuser.root.hosts: *`
	* `hadoop.proxyuser.root.groups: *`
* More Detail:
	* site:hadoop.apache.org/docs/stable/ superusers
	* https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/Superusers.html

####



site:hadoop.apache.org/docs/stable/ superusers

https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/Superusers.html

curl -O https://raw.githubusercontent.com/seanorama/masterclass/master/data/Geolocation.zip


### Kerberos

#### Use the platform before enabling Kerberos

- hadoop fs:

- WebHDFS:
  - https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/WebHDFS.html#Authentication

	```
directory list: curl -sk -L "http://$(hostname -f):50070/webhdfs/v1/?op=LISTSTATUS" | jq '.'
```

Hive:

```
```

#### Lab: Enable Kerberos

https://github.com/abajwa-hw/security-workshops/blob/master/Setup-kerberos-IPA-23.md#enable-kerberos-using-wizard

#### Use the platform after enabling Kerberos

```
sudo su - sean
kinit
curl -k --negotiate -u : "http://$(hostname -f):50070/webhdfs/v1/tmp/?op=LISTSTATUS"
```



### Ranger

#### Managing Authorization before Ranger

```
## HDFS
hadoop fs -mkdir /tmp/example-dir
hadoop fs -chown sean /tmp/testdir
hadoop fs -chmod 755 /tmp/testdir

## Hive

```

#### Deploy Ranger

https://github.com/abajwa-hw/security-workshops/blob/master/Setup-ranger-23.md

#### Managing Authorization with Ranger


