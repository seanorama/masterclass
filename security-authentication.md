# Authentication

## Hadoop security: in non-secured mode (the default)

### There is no authentication

> By default Hadoop runs in non-secure mode in which no actual authentication is required. -- *Apache Hadoop Documentation*

Here we are as the user 'baduser'

```shell
$ hadoop fs -ls /tmp
Found 2 items
drwx-wx-wx   - ambari-qa hdfs          0 2015-07-14 18:38 /tmp/hive
drwx------   - hdfs      hdfs          0 2015-07-14 20:33 /tmp/secure

$ hadoop fs -ls /tmp/secure
ls: Permission denied: user=baduser, access=READ_EXECUTE, inode="/tmp/secure":hdfs:hdfs:drwx------
```
	
Good right?

Look again:

```shell
$ HADOOP_USER_NAME=hdfs hadoop fs -ls /tmp/secure
Found 1 items
drwxr-xr-x   - hdfs hdfs          0 2015-07-14 20:35 /tmp/secure/blah
```
	
Oh my!

That also applies to WebHDFS by using '&user.name=':

```json
$ curl -sk -L "http://$(hostname -f):50070/webhdfs/v1/data/secure/?op=LISTSTATUS" | jq '.'
{
  "RemoteException": {
    "message": "Permission denied: user=dr.who, access=READ_EXECUTE, inode=\"/data/secure\":hdfs:hadoop:drwx------",
    "javaClassName": "org.apache.hadoop.security.AccessControlException",
    "exception": "AccessControlException"
  }
}

$ curl -sk -L "http://$(hostname -f):50070/webhdfs/v1/data/secure/?op=LISTSTATUS&user.name=hdfs" | jq '.'
{
  "FileStatuses": {
    "FileStatus": []
  }
}
```

### Super users (aka proxyuser)

> a superuser can submit jobs or access hdfs on behalf of another user.

https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/Superusers.html

* Critical to the use of many services in Hadoop.
	* Ambari Views
	* Knox
	* Oozie
	* ...

* Configured at `HDFS / core-site`
	* `hadoop.proxyuser.theusername.hosts: *`
	* `hadoop.proxyuser.theusername.groups: *`

* Can be used with WebHDFS (`&doas=`) and most other services:
	`curl -sk -L "http://$(hostname -f):50070/webhdfs/v1/user/?op=LISTSTATUS&user.name=knox&doas=sean"`

--------

## Kerberos

### What is Kerberos?

* See slides

### Kerberos options

* Active Directory
* FreeIPA
* MIT KDC
* ...

### Kerberos Environment

In this workshop we are using FreeIPA to provide Kerberos & LDAP.

> FreeIPA is an integrated security information management solution combining Linux (Fedora), 389 Directory Server, MIT Kerberos, NTP, DNS, Dogtag (Certificate System). It consists of a web interface and command-line administration tools.

* Kerberos Realm: HORTONWORKS.COM
* LDAP Domain: hortonworks.com
* Management User: admin
* Hostname: p-labNN-ipa
* SSH the same as your HDP node


* (optional) WebUI: https://youripahost/ipa/ui/
	* Requires updating your local 'hosts' file'. Execute this on the IPA server to get the line you need:
	* `echo "$(curl -s icanhazip.com) $(hostname -f) $(hostname -s)"`

### Kerberos Commands

* Get a ticket: `kinit`
* Get a ticket for another "principal": `kinit admin`
* List tickets: `klist`
* Destroy tickets: `kdestroy` 

### Managing Kerberos & LDAP with FreeIPA

* Authenticate as KDC admin: `kinit admin`
* Add group: `ipa group-add mygroup --desc mygroup`
* Add user: `ipa user-add myuser --first=first --last=last`
* Set their password: `ipa passwd myuser`
* Add user to group: `ipa group-add-member mygroup --users=myuser`

* If admin user gets locked out: `LDAPTLS_CACERT=/etc/ipa/ca.crt ldappasswd -h localhost -ZZ -D 'cn=directory manager' -W -S uid=admin,cn=users,cn=accounts,dc=hortonworks,dc=com`

### LDAP

* Check if a user comes from local or ldap:

```shell
## normal user:
$ id student
uid=1002(student) gid=1002(student) groups=1002(student),4(adm),39(video),40(dip)

## ldap & user:
$ id gooduser
uid=584200008(gooduser) gid=584200008(gooduser) groups=584200008(gooduser),39(video),584200007(users)
```

*Note that the user has their LDAP & local system groups*

--------

### Lab: Kerberos basics

1. SSH to your IPA host
1. Add a new user from IPA (give it your name)
1. Set it's password
1. Get their kerberos ticket
1. List the kerberos tickets
1. Add them to the IPA group 'users'

--------

## Ambari 



--------

## Knox for perimeter security

> The Apache Knox Gateway is a REST API Gateway for interacting with Hadoop clusters.

Provides kerberos based authentication even when a cluster is in non-secure mode.

https://knox.apache.org/

## Knox Usage

#### WebHDFS

```
curl -skL -u gooduser https://localhost:8443/gateway/default/webhdfs/v1/?op=LISTSTATUS`
```

#### Hive with Beeline

```
beeline

## this will fail since we have a self-signed certificate
> !connect jdbc:hive2://localhost:8443/;ssl=true;transportMode=http;httpPath=gateway/default/hive

## to workaround the self-signed certificate, you provide the keystore details:
> !connect jdbc:hive2://localhost:8443/;ssl=true;sslTrustStore=/var/lib/knox/data/security/keystores/gateway.jks;trustStorePassword=hadoop;transportMode=http;httpPath=gateway/default/hive
```

## Lab: Configuring Knox

* https://github.com/abajwa-hw/security-workshops/blob/master/Setup-knox-23.md

## Hadoop in "Secure Mode"

> By configuring Hadoop runs in secure mode, each user and service needs to be authenticated by Kerberos in order to use Hadoop services. -- *Apache Hadoop Documentation on 
Secure Mode*

* Apache Docs: https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/SecureMode.html

## Lab: Enabling Kerberos (Secure Mode Hadoop) in HDP

The following will walk us through enabling Kerberos on the Cluster

* https://github.com/abajwa-hw/security-workshops/blob/master/Setup-kerberos-IPA-23.md#enable-kerberos-using-wizard

This does not include securing Ambari with Kerberos

## Use the Kerberos cluster

#### 0. Try to run commands without authenticating to kerberos.

```
$ hadoop fs -ls /
15/07/15 14:32:05 WARN ipc.Client: Exception encountered while connecting to the server : javax.security.sasl.SaslException: GSS initiate failed [Caused by GSSException: No valid credentials provided (Mechanism level: Failed to find any Kerberos tgt)]
```

```
$ curl -u someuser -skL "http://$(hostname -f):50070/webhdfs/v1/user/?op=LISTSTATUS"
<title>Error 401 Authentication required</title>
```

#### 1. Get a token

```
## for the current user
sudo su - gooduser
kinit

## for any other user
kinit someuser
```

#### 3. Now you can use the cluster

```
$ hadoop fs -ls /
Found 8 items
[...]
```

```
## note the addition of `--negotiate -u : `
curl -skL --negotiate -u : "http://$(hostname -f):50070/webhdfs/v1/user/?op=LISTSTATUS"
```

```
## note the update to use HTTP and the need to provide the kerberos principal.
beeline -u "jdbc:hive2://localhost:10001/default;transportMode=http;httpPath=cliservice;principal=HTTP/$(hostname -f)@HORTONWORKS.COM"
```