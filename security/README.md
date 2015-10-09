# Notes for our Hadoop Masterclasses

These notes are meant to accompany our Hadoop Security Masterclass.

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

______________________________________________________

## Labs

______________________________________________________

### Lab: Access your Lab

1. Console via SSH or Web
  - SSH
    - User: student
    - Keys: I'll provide a link to them.
      - SSH users: ssh -i student.pri.key student@hostname
      - Putty users: configure the 'student.pri.ppk' here: http://i.imgur.com/Pxp8RGu.png
  - If you cannot use SSH, there is a web console:
    - http://hostname:4200
    - User: student
    - Pass: *the pass we are using throughout the day*

1. Ambari: http://yourhost:8080
  - User: admin
  - Pass: 

______________________________________________________

### Lab: Hadoop proxyuser/superusers & Ambari Views

1. Open the Files Ambari View
2. Notice an error regarding impersonation

In Ambari:
- HDFS -> Configs -> Advanced
- Scroll down to "Custom core-site"
- Click "Add Property"
- Click the icon on the right to use "Bulk property add mode"
- Add these properties:

  ```
hadoop.proxyuser.root.groups=users,hadoop-users
hadoop.proxyuser.root.hosts=*
  ```

______________________________________________________

### Lab: Configure Ambari for LDAP

1. Run this script to save us some time in typing the settings in.
  - Feel free to check the script to see what you would have typed in.

  ```
~/ambari-bootstrap/extras/ambari-ldap-ad.sh

  ```

2. Now let's setup LDAP
  - You should be able to press enter to the defaults
  - EXCEPT for the password. Which I'll share separately.

  ```
sudo ambari-server setup-ldap

  ```

- Restart Ambari services

  ```
sudo ambari-server restart; sudo ambari-agent restart

  ```

- Sync ldap

	```
sudo ambari-server sync-ldap --all

	```

- Provide the username 'admin' and password we are using for the day

- It should look something like this:

  ```
Syncing with LDAP...
Enter Ambari Admin login: admin
Enter Ambari Admin password:
Syncing all............

Completed LDAP Sync.
Summary:
  memberships:
    removed = 0
    created = 56
  users:
    updated = 1
    removed = 0
    created = 49
  groups:
    updated = 0
    removed = 0
    created = 53

Ambari Server 'sync-ldap' completed successfully.

  ```

Try it out:

- Go give user 'student' read-only rights to Ambari
- Login to Ambari as the user 'student'
- See the access

______________________________________________________


<!--
  
- Use these settings. Press Enter for default on lines which end with :
  ```
Setting up LDAP properties...
Primary URL* {host:port} : activedirectory.hortonworks.com:389
Secondary URL {host:port} :
Use SSL* [true/false] (false):
User object class* (posixAccount): user
User name attribute* (uid): sAMAccountName
Group object class* (posixGroup): group
Group name attribute* (cn):
Group member attribute* (memberUid): member
Distinguished name attribute* (dn): distinguishedName
Base DN* : dc=hortonworks,dc=com
Referral method [follow/ignore] :
Bind anonymously* [true/false] (false):
Manager DN*: cn=ldap-connect,ou=users,ou=hdp,dc=hortonworks,dc=com
Enter Manager Password*: BadPass#1
Re-enter password: BadPass#1
====================
Review Settings
====================
authentication.ldap.managerDn: cn=ldap-connect,ou=users,ou=hdp,dc=hortonworks,dc=com
authentication.ldap.managerPassword: *****
Save settings [y/n] (y)? y
Saving...done
Ambari Server 'setup-ldap' completed successfully.
  ```
-->

______________________________________________________

### Lab: Enable Kerberos for HDP using Ambari

1. Kerberos Wizard
  1. Choose Active Directory
  1. Ask your Active Directory administrator (that's me... for what is needed.
    - KDC:
      - KDC host: activedirectory.hortonworks.com
      - Realm name: HORTONWORKS.COM
      - LDAP url: ldaps://activedirectory.hortonworks.com
      - Container DN: ou=lab01,ou=labs,dc=hortonworks,dc=com
      - Domains: c.siq-haas.internal,.c.siq-haas.internal
    - Kadmin
      - Kadmin host: activedirectory.hortonworks.com
      - Admin principal: lab01admin@HORTONWORKS.COM
      - Admin password: BadPass#1
  1. Continue through the wizard
  1. Download & review the Kerberos.csv
  1. If you are happy with the principals, continue through the Wizard

______________________________________________________


### Lab: Using Kerberos

Note: TODO. This needs more material.

1. Authenticate to kerberos & then use the cluster as usual:

```
## auth to kerberos
kinit

## this your token
klist

## use hadoop as usual
hadoop fs -ls /

## destroy your token if needed
kdestroy
```

1. Use the HDFS user:

```
## get kerberos token:
sudo sudo -u hdfs kinit -kt /etc/security/keytabs/hdfs.headless.keytab hdfs-$(hostname -s)

## run commands as usual:
sudo sudo -u hdfs hadoop fs -ls /
```

______________________________________________________

### Lab: Integrate kerberos with the OS

HDP is integrated with Kerberos, but you also need your AD/LDAP groups to be synced with the NameNode & ResourceManagers.

This will only show your local system groups:

  ```
groups
hdfs groups
  ```

- Execute this script to configure SSSD integration with AD:

  ```
ad_pass=BadPass#1 ~/ambari-bootstrap/extras/sssd-kerberos-ad.sh
  ```

- For the changes to take affect:
  - Relogin to your user
  - From Ambari: restart the name node and yarn resource manager

- You shold now see the AD groups:

  ```
groups
hdfs groups
  ```
______________________________________________________

### Lab: Configure Ambari non-root, Keberos JAAS & update views for Kerberos

Enabling Kerberos will break some aspects of Ambari including Ambari Views.

To fix them we will:
- Configure Ambari to run as a non-root user
- Configure Ambari to use Kerberos

- Configure non-root:

```
~/ambari-bootstrap/extras/ambari-non-root.sh
```

- Configure Kerberos JAAS:

```
~/ambari-bootstrap/extras/ambari-kerberos-jaas.sh
```

- Restart services:

```
sudo service ambari-server stop; sudo service ambari-server start; sudo ambari-agent restart
```

- You'll then need to update the Hadoop proxyuser settings for the user 'ambari' & recreate the views:

```
config_proxyuser=true ~/ambari-bootstrap/extras/ambari-views/create-views.sh

```

- One last step will be to restart HDFS

______________________________________________________

### Lab: Onboarding

HDFS does not currently automatically create /user/USERNAME directories.

These directories are required for many operations, such as certain YARN & Hive tasks.

I've written a simple script that takes input of user names and creates their respective directories:

```
export users=$(ldapsearch -Q -H ldap://activedirectory.hortonworks.com -b ou=hdp,dc=hortonworks,dc=com sAMAccountName | awk '/^sAMAccountName: / {print $2}')
~/ambari-bootstrap/extras/onboarding.sh
```

______________________________________________________

### Lab: Install Ranger

- From Ambari, add the Ranger & Ranger KMS services

- Note the requirements for MySQL. In our lab I've taken care of this for you already.

- On the "Customize Services" page __(only fill the red boxes)__
  - All Red Password fields: BadPass#1
  - Ranger settings
    - External URL: http://localhost:6080

- Click next through the rest of the wizard & deploy

- Once complete, access the Ranger Admin:
  - Click Ranger on left side in Ambari, and then access from the Quick Links
  - Credentials: admin/admin

______________________________________________________

### Lab: Enable Ranger for components & configure plugins

You now have Ranger installed but it's not doing anything.

Let's install some plugins, and while we are at it:

- sync LDAP users
- authenticate to Active Directory

```
~/ambari-bootstrap/extras/ranger/ranger-ldap.sh
~/ambari-bootstrap/extras/ranger/ranger-auth-ad.sh
~/ambari-bootstrap/extras/ranger/ranger-plugin-hdfs.sh
~/ambari-bootstrap/extras/ranger/ranger-plugin-hbase.sh
~/ambari-bootstrap/extras/ranger/ranger-plugin-hive.sh
~/ambari-bootstrap/extras/ranger/ranger-plugin-yarn.sh
~/ambari-bootstrap/extras/ranger/ranger-kms.sh
```

- Go back to Ambari and note that a lot of services need restarting.
- Easiest way is to go to your Host in Ambari and click the orange button to restart affected services.

- (optional) install Solr & configure Ranger to store audits in Solr
  - Note this is not a production or secure installation of Solr

```
~/ambari-bootstrap/extras/ranger/solr-dashboard.sh publicip; sleep 20
~/ambari-bootstrap/extras/ranger/ranger-solr-audit.sh
```

______________________________________________________

### Lab: Ranger use Examples & Tips

#### HDFS ACLs
  ```
hadoop fs -ls /public/secured
sudo sudo -u hdfs hadoop fs -chmod 0000 /public/secured
hadoop fs -ls /public/secured
  ```
  
#### Ranger policies

- Add a policy granting access to /public/secured for group 'users'
- Wait a few seconds, and then check the dir again:
  ```
hadoop fs -ls /public/secured
  ```
  
#### Hive best practice:
- Remove global access to /apps/hive/warehouse
  1. Ranger -> HDFS: Give user 'hive' all rights to /apps/hive
  1. Remove HDFS permissions: `sudo sudo -u hdfs hadoop fs -chmod -R 0000 /apps/hive/warehouse`

<!--
## Update default security for Hive
- Fix default policies by adding user 'hive' to both
- Allow Hive to audit to HDFS:
  1. Make the dir: `HADOOP_USER_NAME=hdfs hadoop fs -mkdir /ranger/audit/hiveServer2`
  1. Ranger -> HDFS: Give user 'hive' all rights to /ranger/audit/hiveServer2


## Update security for YARN
- Allow Hive to audit to HDFS:
  1. Make the dir: `HADOOP_USER_NAME=hdfs hadoop fs -mkdir /ranger/audit/yarn`
  1. Ranger -> HDFS: Give user 'yarn' all rights to /ranger/audit/yarn
-->

## Ranger HBase plugin
- Other policies to add/update:
  1. Add HDFS policy: /apps/hbase for user hbase
  1. Add HDFS policy: /ranger/audit/hbaseMaster for user hbase
    - and make the dir `sudo sudo -u hdfs hadoop fs -mkdir -p /ranger/audit/hbaseMaster`
  1. Add HDFS policy: /ranger/audit/hbaseRegional for user hbase
    - and make the dir `sudo sudo -u hdfs hadoop fs -mkdir -p /ranger/audit/hbaseRegional`

______________________________________________________

### Lab: Knox

- Ambari -> Knox -> Configs
- Advanced Topology
- PREPARE YOURSELF FOR EDITING XML
- Note: We are only editing the 1st `<provider>` block
- Update the value for each of these parameters
  - main.ldapRealm: org.apache.shiro.realm.ldap.JndiLdapRealm
  - main.ldapRealm.userDnTemplate: cn={0},ou=users,ou=hdp,dc=hortonworks,dc=com
  - main.ldapRealm.contextFactory.url: ldap://activedirectory.hortonworks.com:389

- It should look like this in the end.
- You could copy this over the current block if you find that easier.

```xml
<provider>
  <role>authentication</role>
  <name>ShiroProvider</name>
  <enabled>true</enabled>
  <param>
    <name>sessionTimeout</name>
    <value>30</value>
  </param>
  <param><name>main.ldapRealm</name>
    <value>org.apache.shiro.realm.ldap.JndiLdapRealm</value>
  </param>
  <param><name>main.ldapRealm.userDnTemplate</name>
    <value>cn={0},ou=users,ou=hdp,dc=hortonworks,dc=com</value>
  </param>
  <param>
    <name>main.ldapRealm.contextFactory.url</name>
    <value>ldap://activedirectory.hortonworks.com:389</value>
  </param>
  <param>
    <name>main.ldapRealm.contextFactory.authenticationMechanism</name>
    <value>simple</value>
  </param>
  <param><name>urls./**</name>
    <value>authcBasic</value>
  </param>
</provider>
```

- Restart Knox

## Use Knox

- Before with WebHDFS:
  ```
curl -ks -u student http://$(hostname -f):50070/webhdfs/v1/user/student/?op=LISTSTATUS | jq '.'
  ```

- Now through Knox:
  ```
curl -ksu student https://localhost:8443/gateway/default/webhdfs/v1/user/student/?op=LISTSTATUS | jq '.'
  ```
______________________________________________________

### Lab: TDE
- Ambari -> Add Service -> Ranger KMS
  - On "customize services" screen:
    - All Passwords *(only the empty fields, they will be in red)*: BadPass#1

### Lab: Use TDE from the command-line

```
## Create and list keys
hadoop key create mytestkey -size 128
hadoop key list -metadata

## Populate some data
hadoop fs -mkdir /user/student/secured
hadoop fs -chmod 700 /user/student/secured
echo "Hello TDE World" > myfile.txt
hadoop fs -put myfile.txt /user/student/secured/

## Create the encryption zone
sudo sudo -u hdfs kinit -kt /etc/security/keytabs/hdfs.headless.keytab hdfs-$(hostname -s)
sudo sudo -u hdfs hdfs crypto -createZone -keyName mytestkey -path /user/student/secured
sudo sudo -u hdfs hdfs crypto -listZones

## View the raw encrypted file as root
sudo sudo -u hdfs hadoop fs -cat /.reserved/raw/user/student/secured/myfile.txt

## Take away rights from root. This cannot be undone.
sudo sudo -u hdfs hadoop fs -setfattr -n security.hdfs.unreadable.by.superuser /user/student/secured/myfile.txt

## Attempt to view the file again
sudo sudo -u hdfs hadoop fs -cat /.reserved/raw/user/student/secured/myfile.txt
```

### Lab: Another version of the TDE command-line lab

1. MAKE KEYS
```
sudo su - hdfs
hadoop key create demoKey256  -size 256
hadoop key list -metadata
```

2. MAKE A ZONE
```
hdfs dfs -mkdir /secure
hdfs crypto -createZone -keyName DemoKey256 -path /secure
hdfs crypto -listZones
```

## Proof

3. Show Local UNENCRYPTED Blocks on Linux OS
```
hdfs fsck /unsecure -blocks -files
0. BP-398503398-10.0.0.31-1438235507347:blk_1073742550_1732 len=44 repl=3

find /data1/hadoop/hdfs/data -name blk_1073742550*

cat /data1/hadoop/hdfs/data/current/BP-398503398-10.0.0.31-1438235507347/current/finalized/subdir0/subdir2/blk_1073742550
```

4. SHOW ENCRYPTED DATA ON OS

```
hdfs fsck /secure -blocks -files
0. BP-398503398-10.0.0.31-1438235507347:blk_1073742903_2089 len=44 repl=3

find /data1/hadoop/hdfs/data -name blk_1073742903*
cat /data1/hadoop/hdfs/data/current/BP-398503398-10.0.0.31-1438235507347/current/finalized/subdir0/subdir4/blk_1073742903
```

5. CAT from HDFS Encrypted File as SHOOTON
```
hdfs dfs -cat /secure/hosts
```

______________________________________________________

______________________________________________________


## Deployment notes

### Deploy your host(s)

Requirements:

  - CentOS 7 (Should also work with CentOS & RedHat 6)
  - Single node without HDP deployed.
    - Look at the setup script if you want to configure on an existing HDP cluster.
  - full sudoers access

### Configure cluster for the masterclass

This should be done on 1 node clusters

- For a single cluster clone this repository and then execute [./setup.sh](./setup.sh)

- If using PDSH or similar commands, you can use curl to execute the script as seen below with PDSH.
    - (make sure to set the hosts_all variable to your host list, or update the command to use a file)

    ```
read -r -d '' command <<EOF
sudo yum -y -q install screen
curl -sSL -O https://raw.githubusercontent.com/seanorama/masterclass/master/security/setup.sh
chmod +x setup.sh
screen -S myscreen /home/student/setup.sh
EOF
pdsh -w ${hosts_all} "${command}"
    ```
