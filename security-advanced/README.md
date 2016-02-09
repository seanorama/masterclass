# Contents

- [Lab 1](https://github.com/seanorama/masterclass/tree/master/security-advanced#lab-1)
  - Access cluster
  - Install Knox
  - Security w/o kerberos
- [Lab 2](https://github.com/seanorama/masterclass/tree/master/security-advanced#lab-2)
  - AD overview
  - Configure Name Resolution & AD Certificate
  - Setup Access to Active Directory Server
  - Enable Active Directory Authentication for Ambari
- [Lab 3](https://github.com/seanorama/masterclass/tree/master/security-advanced#lab-3)
  - Kerborize cluster
  - Setup AD/Operating System Integration using SSSD - AD KDC
- [Lab 4](https://github.com/seanorama/masterclass/tree/master/security-advanced#lab-4)
  - Ambari Server Security
    - Kerberos for Ambari
    - Ambari server as non-root
    - Ambari Encrypt Database and LDAP Passwords
    - SSL For Ambari server
    - SPNEGO
- [Lab 5](https://github.com/seanorama/masterclass/tree/master/security-advanced#lab-5)
  - Ranger install pre-reqs
  - Ranger install
- [Lab 6](https://github.com/seanorama/masterclass/tree/master/security-advanced#lab-6)
  - Ranger KMS install
  - HDFS encryption exercises
  - Move Hive warehouse to EZ?
- [Lab 7](https://github.com/seanorama/masterclass/tree/master/security-advanced#lab-7)
  - Secured Hadoop exercises
    - HDFS
    - Hive
    - HBase
    - Sqoop
- [Lab 8](https://github.com/seanorama/masterclass/tree/master/security-advanced#lab-8)
  - Configure Knox to authenticate via AD
  - Utilize Knox to Connect to Hadoop  Cluster Services
    - WebHDFS
    - Hive?
- [Lab 9](https://github.com/seanorama/masterclass/tree/master/security-advanced#lab-9---optional)
  - Configure Ambari views for kerberos?

---------------

# Lab 1

## Accessing your Cluster

Credentials will be provided for these services by the instructor:

* SSH
* Ambari

## Use your Cluster

### To connect using Putty from Windows laptop

- Download ppk from [here](https://github.com/seanorama/masterclass/raw/master/security-advanced/training-keypair.ppk)
- Use putty to connect to your nodes

### To connect from Linux/MacOSX laptop

- SSH into Ambari node of your cluster using below steps:
  - Right click [this pem key](https://github.com/seanorama/masterclass/blob/master/security-advanced/training-keypair.pem)  > Save link as > save to Downloads folder
  - Copy pem key to ~/.ssh dir and correct permissions
  ```
  cp ~/Downloads/training-keypair.pem ~/.ssh/
  chmod 400 ~/.ssh/training-keypair.pem
  ```
 - Login to the Ambari node of the cluster you have been assigned by replacing IP_ADDRESS_OF_AMBARI_NODE below with Ambari node IP Address (your instructor will provide this)   
  ```
  ssh -i  ~/.ssh/training-keypair.pem centos@IP_ADDRESS_OF_AMBARI_NODE
  ```
  - To change user to root you can:
  ```
  sudo su -
  ```


#### Finding internal/external hosts

- Following are useful techniques you can use in future labs to find your cluster specific details:

  - From SSH terminal, how can I find the cluster name?
  ```
  #run on ambari node to fetch cluster name via Ambari API
  PASSWORD=BadPass#1
  output=`curl -u admin:$PASSWORD -i -H 'X-Requested-By: ambari'  http://localhost:8080/api/v1/clusters`
  cluster=`echo $output | sed -n 's/.*"cluster_name" : "\([^\"]*\)".*/\1/p'`
  echo $cluster
  ```
  - From SSH terminal, how can I find internal hostname (aka FQDN) of the node I'm logged into?
  ```
  $ hostname -f
  ip-172-30-0-186.us-west-2.compute.internal  
  ```

  - From SSH terminal, how can I to find external (public) IP  of the node I'm logged into?
  ```
  $ curl icanhazip.com
  54.68.246.157  
  ```
  
  - From Ambari how do I check the cluster name?
    - It is displayed on the top left of the Ambari dashboard, next to the Ambari logo. If the name appears truncated, you can hover over it to produce a helptext dialog with the full name
    ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/clustername.png)
  
  - From Ambari how can I find external hostname of node where a component (e.g. Resource Manager) is installed?
    - Click the parent service (e.g. YARN) and *hover over* the name of the component. The external hostname will appear.
    ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ambari-RM-public-host.png)  

  - From Ambari how can I find internal hostname of node where a component (e.g. Resource Manager) is installed?
    - Click the parent service (e.g. YARN) and *click on* the name of the component. It will take you to hosts page of that node and display the internal hostname on the top.
    ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ambari-YARN-internal-host.png)  
  
#### Import sample data into Hive 

- Run below *on hive node* to download data and import it into a Hive table for later labs
  ```
  cd /tmp
  wget https://raw.githubusercontent.com/abajwa-hw/security-workshops/master/data/sample_07.csv
  wget https://raw.githubusercontent.com/abajwa-hw/security-workshops/master/data/sample_08.csv
  ```
  - Create user dir for admin, sales1 and hr1
  ```
   sudo -u hdfs hadoop fs  -mkdir /user/admin
   sudo -u hdfs hadoop fs  -chown admin:hadoop /user/admin

   sudo -u hdfs hadoop fs  -mkdir /user/sales1
   sudo -u hdfs hadoop fs  -chown sales1:hadoop /user/sales1
   
   sudo -u hdfs hadoop fs  -mkdir /user/hr1
   sudo -u hdfs hadoop fs  -chown hr1:hadoop /user/hr1   
  ```
    
  - Now create Hive table in default database by either
    - logging into ambari as admin and run this via Hive view (one statement at a time) e.g. http://52.32.113.77:8080/#/main/views/HIVE/1.0.0/AUTO_HIVE_INSTANCE
    - Or starting beeline shell from the node where Hive is installed: `beeline -u "jdbc:hive2://localhost:10000/default"`
```
CREATE TABLE `sample_07` (
`code` string ,
`description` string ,  
`total_emp` int ,  
`salary` int )
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TextFile;
```
```
load data local inpath '/tmp/sample_07.csv' into table sample_07;
```
```
CREATE TABLE `sample_08` (
`code` string ,
`description` string ,  
`total_emp` int ,  
`salary` int )
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TextFile;
```
```
load data local inpath '/tmp/sample_08.csv' into table sample_08;
```

- Notice that in the JDBC connect string for connecting to an unsecured Hive while its running in default (ie binary) transport mode :
  - port is 10000
  - no kerberos principal was needed 

- This will change after we:
  - enable kerberos
  - configure Hive for http transport mode (to go through Knox)
    
### Why is security needed?


##### HDFS access on unsecured cluster

- On your unsecured cluster try to access a restricted dir in HDFS
```
hdfs dfs -ls /tmp/hive   
## this should fail with Permission Denied
```

- Now try again after setting HADOOP_USER_NAME env var
```
export HADOOP_USER_NAME=hdfs
hdfs dfs -ls /tmp/hive   
## this shows the file listing!
```
- Unset the env var and it will fail again
```
unset HADOOP_USER_NAME
hdfs dfs -ls /tmp/hive  
```

##### WebHDFS access on unsecured cluster

- From *node running NameNode*, make a WebHDFS request using below command:
```
curl -sk -L "http://$(hostname -f):50070/webhdfs/v1/user/?op=LISTSTATUS
```

- In the absence of Knox, notice it goes over HTTP (not HTTPS) on port 50070 and no credentials were needed

##### Web UI access on unsecured cluster

- From Ambari notice you can open the WeUIs without any authentication
  - HDFS > Quicklinks > NameNode UI
  - Madreduce > Quicklinks > JobHistory UI
  - YARN > Quicklinks > ResourceManager UI
    
- This should tell you why kerberos is needed on Hadoop :)


### Manually install missing components

- Login to Ambari web UI by opening http://AMBARI_PUBLIC_IP:8080 and log in with admin/BadPass#1
- Use the 'Add Service' Wizard to install Knox and Hbase, if not already installed
  - When prompted for the Knox password, set it to `BadPass#1`

- We will use Knox further in a later exercise.

-----------------------------

# Lab 2

### AD overview

- Active Directory will already be setup by the instructor. A basic structure of OrganizationalUnits will have been pre-created to look something like the below:
  - CorpUsers OU, which contains:
    - business users and groups (e.g. it1, hr1, legal1) and 
    - hadoopadmin: Admin user (for AD, Ambari, ...)
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/AD-corpusers.png)
  
  - ServiceUsers OU: service users - that would not be created by Ambari  (e.g. rangeradmin, ambari etc)
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/AD-serviceusers.png)
  
  - HadoopServices OU: hadoop service principals (will be created by Ambari)
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/AD-hadoopservices.png)  
  
  - HadoopNodes OU: list of nodes registered with AD
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/AD-hadoopnodes.png)

- In addition, the below steps would have been completed in advance [per doc](http://docs.hortonworks.com/HDPDocuments/Ambari-2.2.0.0/bk_Ambari_Security_Guide/content/_use_an_existing_active_directory_domain.html):
  - Ambari Server and cluster hosts have network access to, and be able to resolve the DNS names of, the Domain Controllers.
  - Active Directory secure LDAP (LDAPS) connectivity has been configured.
  - Active Directory User container for principals has been created and is on-hand. For example, "ou=HadoopServices,dc=lab,dc=hortonworks,dc=net"
  - Active Directory administrative credentials with delegated control of "Create, delete, and manage user accounts" on the previously mentioned User container are on-hand. e.g. hadoopadmin


- For general info on Active Directory refer to Microsoft website [here](https://technet.microsoft.com/en-us/library/cc780336(v=ws.10).aspx) 


### Configure name resolution & certificate to Active Directory

**Run below on all nodes**

1. Add your Active Directory to /etc/hosts (if not in DNS). Make sure you replace the IP address of your AD from your instructor.
  - **Change the IP to match your ADs internal IP**
   ```
ad_ip=GET_THE_AD_IP_FROM_YOUR_INSTRUCTOR
echo "${ad_ip} ad01.lab.hortonworks.net ad01" | sudo tee -a /etc/hosts
   ```

2. Add your CA certificate (if using self-signed & not already configured)
  - In this case we have pre-exported the CA cert from our AD and made available for download. 
   ```
cert_url=https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/extras/ca.crt
sudo yum -y install openldap-clients ca-certificates
sudo curl -sSL "${cert_url}" -o /etc/pki/ca-trust/source/anchors/hortonworks-net.crt

sudo update-ca-trust force-enable
sudo update-ca-trust extract
sudo update-ca-trust check
   ```

3. Test certificate & name resolution with `ldapsearch`

   ```
## Update ldap.conf with our defaults
sudo tee -a /etc/openldap/ldap.conf > /dev/null << EOF
TLS_CACERT /etc/pki/tls/cert.pem
URI ldaps://ad01.lab.hortonworks.net ldap://ad01.lab.hortonworks.net
BASE dc=lab,dc=hortonworks,dc=net
EOF

## test by running below (LDAP password is: BadPass#1)
ldapsearch -W -D ldap-reader@lab.hortonworks.net

openssl s_client -connect ad01:636 </dev/null
   ```

**Now repeat above steps on all nodes**


### Setup Ambari/AD sync

Run below on only Ambari node:

1. Add your AD properties as defaults for Ambari LDAP sync  

  ```
ad_dc="ad01.lab.hortonworks.net"
ad_root="ou=CorpUsers,dc=lab,dc=hortonworks,dc=net"
ad_user="cn=ldap-reader,ou=ServiceUsers,dc=lab,dc=hortonworks,dc=net"

sudo tee -a /etc/ambari-server/conf/ambari.properties > /dev/null << EOF
authentication.ldap.baseDn=${ad_root}
authentication.ldap.managerDn=${ad_user}
authentication.ldap.primaryUrl=${ad_dc}:389
authentication.ldap.bindAnonymously=false
authentication.ldap.dnAttribute=distinguishedName
authentication.ldap.groupMembershipAttr=member
authentication.ldap.groupNamingAttr=cn
authentication.ldap.groupObjectClass=group
authentication.ldap.useSSL=false
authentication.ldap.userObjectClass=user
authentication.ldap.usernameAttribute=sAMAccountName
EOF

  ```
  
2. Run Ambari LDAP sync. 
 - Press enter at each prompt to accept the default value being displayed
 - When prompted for 'Manager Password' at the end, enter password : BadPass#1
  ```
  sudo ambari-server setup-ldap
  ```

3. Reestart Ambari server and agents
  ```
   sudo ambari-server restart
   sudo ambari-agent restart
  ```
4. Run LDAPsync to sync only the groups we want
  - When prompted for user/password, use the *local* Ambari admin credentials (i.e. admin/BadPass#1)
  ```
  echo hadoop-users,hr,sales,legal,hadoop-admins > groups.txt
  sudo ambari-server sync-ldap --groups groups.txt
  ```

  - This should show a summary of what objects were created
  ```
  Completed LDAP Sync.
  Summary:
    memberships:
      removed = 0
      created = 25
    users:
      updated = 0
      removed = 0
      created = 15
    groups:
      updated = 0
      removed = 0
      created = 5
  ``` 
  
5. Give 'hadoop-admins' permissions to manage the cluster
  - Login to Ambari as your local 'admin' user (i.e. admin/BadPass#1)
  - Grant 'hadoopadmin' user permissions to manage the cluster:
    - Click the dropdown on top right of Ambari UI
    - Click 'Manage Ambari'
    - Under 'Users', select 'hadoopadmin'
    - Change 'Ambari Admin' to Yes 
  - Logout and log back into Ambari as 'hadoopadmin' and verify the user has rights to manage the cluster

6. (optional) Disable local 'admin' user

# Lab 3
 
## Kerberize the Cluster

### Run Ambari Kerberos Wizard against Active Directory environment

Enable kerberos using Ambari security wizard (under 'Admin' tab > Kerberos). Enter the below details:

- KDC:
    - KDC host: ad01.lab.hortonworks.net
    - Realm name: LAB.HORTONWORKS.NET
    - LDAP url: ldaps://ad01.lab.hortonworks.net
    - Container DN: ou=HadoopServices,dc=lab,dc=hortonworks,dc=net
    - Domains: us-west-2.compute.internal,.us-west-2.compute.internal
- Kadmin:
    - Kadmin host: ad01.lab.hortonworks.net
    - Admin principal: hadoopadmin@LAB.HORTONWORKS.NET
    - Admin password: BadPass#1

- Then click Next on all the following screens to pick the default values

### Setup AD/OS integration via SSSD

- Why? 
  - Currently your hadoop nodes do not recognize users/groups defined in AD.
  - You can check this by running below:
  ```
  id it1
  groups it1
  ```
-  Pre-req for below steps: Your AD admin/instructor should have given 'registersssd' user permissions to add the workstation to OU=HadoopNodes (needed to run 'adcli join' successfully)

- Run below **on each node**
```
ad_user="registersssd"
ad_domain="lab.hortonworks.net"
ad_dc="ad01.lab.hortonworks.net"
ad_root="dc=lab,dc=hortonworks,dc=net"
ad_ou="ou=HadoopNodes,${ad_root}"
ad_realm=${ad_domain^^}

sudo kinit ${ad_user}
```

- Run below on each node
```
sudo yum makecache fast
sudo yum -y -q install epel-release ## epel is required for adcli
sudo yum -y -q install sssd oddjob-mkhomedir authconfig sssd-krb5 sssd-ad sssd-tools
sudo yum -y -q install adcli

#copy next 7 lines together
sudo adcli join -v \
  --domain-controller=${ad_dc} \
  --domain-ou="${ad_ou}" \
  --login-ccache="/tmp/krb5cc_0" \
  --login-user="${ad_user}" \
  -v \
  --show-details

#copy/paste from next line until second EOF in one shot
sudo tee /etc/sssd/sssd.conf > /dev/null <<EOF
[sssd]
## master & data nodes only require nss. Edge nodes require pam.
services = nss, pam, ssh, autofs, pac
config_file_version = 2
domains = ${ad_realm}
override_space = _

[domain/${ad_realm}]
id_provider = ad
ad_server = ${ad_dc}
#ad_server = ad01, ad02, ad03
#ad_backup_server = ad-backup01, 02, 03
auth_provider = ad
chpass_provider = ad
access_provider = ad
enumerate = False
krb5_realm = ${ad_realm}
ldap_schema = ad
ldap_id_mapping = True
cache_credentials = True
ldap_access_order = expire
ldap_account_expire_policy = ad
ldap_force_upper_case_realm = true
fallback_homedir = /home/%d/%u
default_shell = /bin/false
ldap_referrals = false

[nss]
memcache_timeout = 3600
override_shell = /bin/bash
EOF

sudo chmod 0600 /etc/sssd/sssd.conf
sudo service sssd restart
sudo authconfig --enablesssd --enablesssdauth --enablemkhomedir --enablelocauthorize --update

sudo chkconfig oddjobd on
sudo service oddjobd restart
sudo chkconfig sssd on
sudo service sssd restart

sudo kdestroy
```
- Test your nodes can recognize AD users
```
id sales1
groups sales1
```

### Refresh HDFS User-Group mappings

- Once the above is completed on all nodes you need to refresh the user group mappings in HDFS & YARN by running the below commands

- Execute the following on the Ambari node:
```
export PASSWORD=BadPass#1

#detect name of cluster
output=`curl -u hadoopadmin:$PASSWORD -i -H 'X-Requested-By: ambari'  http://localhost:8080/api/v1/clusters`
cluster=`echo $output | sed -n 's/.*"cluster_name" : "\([^\"]*\)".*/\1/p'`

#refresh user and group mappings
sudo sudo -u hdfs kinit -kt /etc/security/keytabs/hdfs.headless.keytab hdfs-${cluster}
sudo sudo -u hdfs hdfs dfsadmin -refreshUserToGroupsMappings
```

Execute the following on the node where the YARN ResourceManager is installed:
```
sudo sudo -u yarn kinit -kt /etc/security/keytabs/yarn.service.keytab yarn/$(hostname -f)@LAB.HORTONWORKS.NET
sudo sudo -u yarn yarn rmadmin -refreshUserToGroupsMappings
```

- kinit as a normal Hadoop user
```
kinit hr1
```

- check the users groups
```
hdfs groups
yarn rmadmin -getGroups hr1
```

- output should look like:
```
hr1@LAB.HORTONWORKS.NET : domain_users hadoop-users hr
```

### Test OS/AD integration and Kerberos security

- Login as sales1 user and try to access the same /tmp/hive HDFS dir
```
sudo su - sales1

hdfs dfs -ls /tmp/hive   
## since we did not authenticate, this fails with GSSException: No valid credentials provided

#authenticate
kinit
##enter BadPass#1

klist
## shows the principal for sales1

hdfs dfs -ls /tmp/hive 
## fails with Permission denied

#Now try to get around security by setting the same env variable
export HADOOP_USER_NAME=hdfs
hdfs dfs -ls /tmp/hive 

```
- Notice that now that the cluster is kerborized, we were not able to circumvent security by setting the env var 

--------------

# Lab 4

## Security options for Ambari

Reference: Doc available [here](http://docs.hortonworks.com/HDPDocuments/Ambari-2.2.0.0/bk_Ambari_Security_Guide/content/ch_amb_sec_guide.html)

### Kerberos for Ambari

- Setup kerberos for Ambari
  - Required to configure Ambari views for kerberos

```
# run on Ambari node to start security setup guide
cd /etc/security/keytabs/
sudo wget https://github.com/seanorama/masterclass/raw/master/security-advanced/extras/ambari.keytab
sudo chown ambari:hadoop ambari.keytab
sudo chmod 400 ambari.keytab
sudo ambari-server stop
sudo ambari-server setup-security
```
- Enter below when prompted (sample output shown below):
  - choice: `3`
  - principal: `ambari@LAB.HORTONWORKS.NET`
  - keytab path: `/etc/security/keytabs/ambari.keytab`
  
- Sample output:  
```
Using python  /usr/bin/python2.7
Security setup options...
===========================================================================
Choose one of the following options:
  [1] Enable HTTPS for Ambari server.
  [2] Encrypt passwords stored in ambari.properties file.
  [3] Setup Ambari kerberos JAAS configuration.
  [4] Setup truststore.
  [5] Import certificate to truststore.
===========================================================================
Enter choice, (1-5): 3
Setting up Ambari kerberos JAAS configuration to access secured Hadoop daemons...
Enter ambari server's kerberos principal name (ambari@EXAMPLE.COM): ambari@LAB.HORTONWORKS.NET
Enter keytab path for ambari server's kerberos principal: /etc/security/keytabs/ambari.keytab
Ambari Server 'setup-security' completed successfully.
```

- Restart Ambari to changes to take affect
```
sudo ambari-server restart
sudo ambari-server restart
sudo ambari-agent restart
```

### Ambari server as non-root
- To setup Ambari server as non-root run below on Ambari-server node:
```
sudo ambari-server setup
```
- Then enter the below at the prompts:
  - OK to continue? y
  - Customize user account for ambari-server daemon? y
  - Enter user account for ambari-server daemon (root):ambari
  - Do you want to change Oracle JDK [y/n] (n)? n
  - Enter advanced database configuration [y/n] (n)? n

- Sample output:
```
$ sudo ambari-server setup
Using python  /usr/bin/python2
Setup ambari-server
Checking SELinux...
SELinux status is 'enabled'
SELinux mode is 'permissive'
WARNING: SELinux is set to 'permissive' mode and temporarily disabled.
OK to continue [y/n] (y)? y
Customize user account for ambari-server daemon [y/n] (n)? y
Enter user account for ambari-server daemon (root):ambari
Adjusting ambari-server permissions and ownership...
Checking firewall status...
Redirecting to /bin/systemctl status  iptables.service

Checking JDK...
Do you want to change Oracle JDK [y/n] (n)? n
Completing setup...
Configuring database...
Enter advanced database configuration [y/n] (n)? n
Configuring database...
Default properties detected. Using built-in database.
Configuring ambari database...
Checking PostgreSQL...
Configuring local database...
Connecting to local database...done.
Configuring PostgreSQL...
Backup for pg_hba found, reconfiguration not required
Extracting system views...
.......
Adjusting ambari-server permissions and ownership...
Ambari Server 'setup' completed successfully.
```

### Ambari Encrypt Database and LDAP Passwords

- Needed to allow Ambari to cache the admin password so its not prompted for each each you add, move or remove a service via Ambari

- To encrypt password, run below
```
sudo ambari-server stop
sudo ambari-server setup-security
```
- Then enter the below at the prompts:
  - enter choice: 2
  - provide master key: BadPass#1
  - re-enter master key: BadPass#1
  - do you want to persist? y

- Then start ambari
```
sudo ambari-server start
```  
- Sample output
```
$ sudo ambari-server setup-security
Using python  /usr/bin/python2
Security setup options...
===========================================================================
Choose one of the following options:
  [1] Enable HTTPS for Ambari server.
  [2] Encrypt passwords stored in ambari.properties file.
  [3] Setup Ambari kerberos JAAS configuration.
  [4] Setup truststore.
  [5] Import certificate to truststore.
===========================================================================
Enter choice, (1-5): 2
Please provide master key for locking the credential store:
Re-enter master key:
Do you want to persist master key. If you choose not to persist, you need to provide the Master Key while starting the ambari server as an env variable named AMBARI_SECURITY_MASTER_KEY or the start will prompt for the master key. Persist [y/n] (y)? y
Adjusting ambari-server permissions and ownership...
Ambari Server 'setup-security' completed successfully.
```

### SSL For Ambari server

- Enables Ambari WebUI to run on HTTPS instead of HTTP

#### Create self-signed certificate

- Commands and sample output below (to be run on ambari node):
  - Note that for 'Common Name' you should enter the public hostname of Ambari node
  
```
$ openssl genrsa -out ambari.key 2048
Generating RSA private key, 2048 bit long modulus
....+++
.........+++
e is 65537 (0x10001)

$ openssl req -new -key ambari.key -out ambari.csr
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [XX]:US
State or Province Name (full name) []:CA
Locality Name (eg, city) [Default City]:Santa Clara
Organization Name (eg, company) [Default Company Ltd]:Hortonworks
Organizational Unit Name (eg, section) []:Sales
Common Name (eg, your name or your server's hostname) []:ec2-52-32-113-77.us-west-2.compute.amazonaws.com
Email Address []:

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:

$ openssl x509 -req -days 365 -in ambari.csr -signkey ambari.key -out ambari.crt
Signature ok
subject=/C=US/ST=CA/L=Santa Clara/O=Hortonworks/OU=Sales/CN=lab.hortonworks.net/emailAddress=admin@hortonworks.com
Getting Private key
```

- This generates:
  - certificate: ambari.crt
  - private key: ambari.key

- Copy the 3 files into a new folder called ssl under /etc/security (ambari.key, ambari.csr, ambari.crt)
```
mkdir /etc/security/ssl
cp ambari.* /etc/security/ssl
```

- Proceed onto next section on enable HTTPS for Ambari

#### Setup SSL for Ambari server

- Stop Ambari server
```
ambari-server stop
```

- Setup HTTPS for Ambari  
```
# ambari-server setup-security
Using python  /usr/bin/python2
Security setup options...
===========================================================================
Choose one of the following options:
  [1] Enable HTTPS for Ambari server.
  [2] Encrypt passwords stored in ambari.properties file.
  [3] Setup Ambari kerberos JAAS configuration.
  [4] Setup truststore.
  [5] Import certificate to truststore.
===========================================================================
Enter choice, (1-5): 1
Do you want to configure HTTPS [y/n] (y)? y
SSL port [8443] ? 8443
Enter path to Certificate: /etc/security/ssl/ambari.crt
Enter path to Private Key: /etc/security/ssl/ambari.key
Please enter password for Private Key: BadPass#1
Importing and saving Certificate...done.
Adjusting ambari-server permissions and ownership...
```

- Start ambari back up
```
ambari-server start
```

- Now you can access Ambari on HTTPS on port 8443 e.g. https://ec2-52-32-113-77.us-west-2.compute.amazonaws.com:8443


### SPNEGO

- Needed to secure the Hadoop components webUIs (e.g. Namenode UI, JobHistory UI, Yarn ResourceManager UI etc...)

- Login to ambari node as root
```
sudo su
```
- Create Secret Key Used for Signing Authentication Tokens
```
dd if=/dev/urandom of=/etc/security/http_secret bs=1024 count=1
chown hdfs:hadoop /etc/security/http_secret
chmod 440 /etc/security/http_secret
```
- Place file in Ambari resources dir so it gets pushes to all nodes
```
cp /etc/security/http_secret /var/lib/ambari-server/resources/host_scripts/
ambari-server restart
```

- On all the other nodes, after the http_secret file appears under /var/lib/ambari-agent/cache/host_scripts...

- Run below as root to put it in right dir and correct its permissions
```
cp /var/lib/ambari-agent/cache/host_scripts/http_secret /etc/security/
chown hdfs:hadoop /etc/security/http_secret
chmod 440 /etc/security/http_secret
```

- logoff root on each node
```
logoff
```


- In Ambari > HDFS > Configs, set the below
  - Advanced core-site:
    - hadoop.http.authentication.simple.anonymous.allowed = false
  
  - Custom core-site set the below (using bulk edit tab):
    - hadoop.http.authentication.signature.secret.file = /etc/security/http_secret
    - hadoop.http.authentication.typ= kerberos
    - hadoop.http.authentication.kerberos.keytab = /etc/security/keytabs/spnego.service.keytab
    - hadoop.http.authentication.kerberos.principal = HTTP/_HOST@HORTONWORKS.COM
    - hadoop.http.authentication.cookie.domain = hortonworks.com

  - In Custom core-site, double check that the below is already set:
    - hadoop.http.filter.initializers = org.apache.hadoop.security.AuthenticationFilterInitializer


- Restart all services that require restart (HDFS, Mapreduce, YARN)

- Now when you try to open any of the web UIs like below you will get `401: Authentication required`
  - HDFS: Namenode UI
  - Mapreduce: Job history UI
  - YARN: Resource Manager UI

- **TODO**: Show how to open these UIs via kerborized browser

### Ambari views 

Ambari views setup on secure cluster will be covered in later lab ([here](https://github.com/seanorama/masterclass/tree/master/security-advanced#other-security-features-for-ambari))

------------------

# Lab 5

## Ranger 

### Ranger prereqs

##### Create & confirm MySQL user 'root'

Prepare MySQL DB for Ranger use. Run these steps on the node where MySQL is located
- `sudo mysql`
- Execute following in the MySQL shell. Change the password to your preference. 

    ```sql
CREATE USER 'root'@'%';
GRANT ALL PRIVILEGES ON *.* to 'root'@'%' WITH GRANT OPTION;
SET PASSWORD FOR 'root'@'%' = PASSWORD('BadPass#1');
SET PASSWORD = PASSWORD('BadPass#1');
FLUSH PRIVILEGES;
exit
```

- Confirm MySQL user: `mysql -u root -h $(hostname -f) -p -e "select count(user) from mysql.user;"`
  - Output should be a simple count. Check the last step if there are errors.

##### Prepare Ambari for MySQL
- Run this on Ambari node
- Add MySQL JAR to Ambari:
  - `sudo ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar`
    - If the file is not present, it is available on RHEL/CentOS with: `sudo yum -y install mysql-connector-java`

##### Install SolrCloud from HDPSearch for Audits (if not already installed)


###### Option 1: Install Solr manually

- Manually install Solr *on each node where Zookeeper is running*
```
export JAVA_HOME=/usr/java/default   
sudo yum -y install lucidworks-hdpsearch
```

###### Option 2: Use Ambari service for Solr

- Install Ambari service for Solr
```
VERSION=`hdp-select status hadoop-client | sed 's/hadoop-client - \([0-9]\.[0-9]\).*/\1/'`
sudo git clone https://github.com/abajwa-hw/solr-stack.git /var/lib/ambari-server/resources/stacks/HDP/$VERSION/services/SOLR
sudo ambari-server restart
```
- Login to Ambari as hadoopadmin and wait for all the services to turn green
- Install Solr by starting the 'Add service' wizard (using 'Actions' dropdown) and choosing Solr. Pick the defaults in the wizard except:
  - On the screen where you choose where to put Solr, use the + button next to Solr to add Solr to *each host that runs a Zookeeper Server*
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/solr-service-placement.png)
  
  - On the screen to Customize the Solr service
    - under 'Advanced solr-config':
      - set `solr.datadir` to `/opt/ranger_audit_server`    
      - set `solr.download.location` to `HDPSEARCH`
      - set `solr.znode` to `/ranger_audits`
    - under 'Advanced solr-env':
      - set `solr.port` to `6083`
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/solr-service-configs.png)  

- Under Configure Identities page, you will have to enter your AD admin credentials:
  - Admin principal: hadoopadmin@LAB.HORTONWORKS.NET
  - Admin password: BadPass#1

- Then go through the rest of the install wizard by clicking Next to complete installation of Solr

- (Optional) In case of failure, run below from Ambari node to delete the service so you can try again:
```
export SERVICE=SOLR
export AMBARI_HOST=localhost
export PASSWORD=BadPass#1
output=`curl -u hadoopadmin:$PASSWORD -i -H 'X-Requested-By: ambari'  http://localhost:8080/api/v1/clusters`
CLUSTER=`echo $output | sed -n 's/.*"cluster_name" : "\([^\"]*\)".*/\1/p'`

#attempt to unregister the service
curl -u admin:$PASSWORD -i -H 'X-Requested-By: ambari' -X DELETE http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER/services/$SERVICE

#in case the unregister service resulted in 500 error, run the below first and then retry the unregister API
#curl -u admin:$PASSWORD -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop $SERVICE via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER/services/$SERVICE

sudo service ambari-server restart

#restart agents on all nodes
sudo service ambari-agent restart
```

###### Setup Solr for Ranger audit 

- Once Solr is installed, run below to set it up for Ranger audits. Steps are based on http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.2/bk_Ranger_Install_Guide/content/solr_ranger_configure_solrcloud.html

- Run on all nodes where Solr was installed
```
export JAVA_HOME=/usr/java/default
export host=$(curl -4 icanhazip.com)

sudo wget https://issues.apache.org/jira/secure/attachment/12761323/solr_for_audit_setup_v3.tgz -O /usr/local/solr_for_audit_setup_v3.tgz
cd /usr/local
sudo tar xvf solr_for_audit_setup_v3.tgz
cd /usr/local/solr_for_audit_setup
sudo mv install.properties install.properties.org

sudo tee install.properties > /dev/null <<EOF
#!/bin/bash
JAVA_HOME=$JAVA_HOME
SOLR_USER=solr
SOLR_INSTALL=false
SOLR_INSTALL_FOLDER=/opt/lucidworks-hdpsearch/solr
SOLR_RANGER_HOME=/opt/ranger_audit_server
SOLR_RANGER_PORT=6083
SOLR_DEPLOYMENT=solrcloud
SOLR_ZK=localhost:2181/ranger_audits
SOLR_HOST_URL=http://$host:\${SOLR_RANGER_PORT}
SOLR_SHARDS=1
SOLR_REPLICATION=2
SOLR_LOG_FOLDER=/var/log/solr/ranger_audits
SOLR_MAX_MEM=1g
EOF
sudo ./setup.sh

# create ZK dir - only needs to be run from one of the Solr nodes
sudo /opt/ranger_audit_server/scripts/add_ranger_audits_conf_to_zk.sh

# if you installed Solr via Ambari, skip this step that starts solr 
# otherwise, run on each Solr node to start it in Cloud mode
sudo /opt/ranger_audit_server/scripts/start_solr.sh

# create collection - only needs to be run from one of the Solr nodes
sudo sed -i 's,^SOLR_HOST_URL=.*,SOLR_HOST_URL=http://localhost:6083,' \
   /opt/ranger_audit_server/scripts/create_ranger_audits_collection.sh
sudo /opt/ranger_audit_server/scripts/create_ranger_audits_collection.sh 

```

- Now you should access Solr webui at http://publicIP:6083/solr
  - Click the Cloud > Graph tab to find the leader host (172.30.0.242 in below example)
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/solr-cloud.png)   

- (Optional) - On the leader node, install SILK (banana) dashboard to visualize audits in Solr
```
sudo wget https://raw.githubusercontent.com/abajwa-hw/security-workshops/master/scripts/default.json -O /opt/lucidworks-hdpsearch/solr/server/solr-webapp/webapp/banana/app/dashboards/default.json
export host=$(curl -4 icanhazip.com)
# replace host/port in this line::: "server": "http://sandbox.hortonworks.com:6083/solr/",
sudo sed -i "s,sandbox.hortonworks.com,$host," \
   /opt/lucidworks-hdpsearch/solr/server/solr-webapp/webapp/banana/app/dashboards/default.json
sudo chown solr:solr /opt/lucidworks-hdpsearch/solr/server/solr-webapp/webapp/banana/app/dashboards/default.json
# access banana dashboard at http://hostname:6083/solr/banana/index.html
```
- At this point you should be able to: 
  - access Solr webui at http://hostname:6083/solr
  - access banana dashboard (if installed earlier) at http://hostname:6083/solr/banana/index.html 
    - this will currently not have any audit data  


## Ranger install

##### Install Ranger via Ambari 2.2

- Using Amabris 'Add Service' wizard, install Ranger on any node you like. Set the below configs for below tabs:

1. Ranger Admin tab:
  - Ranger DB Host = FQDN of host where Mysql is running (e.g. ip-172-30-0-242.us-west-2.compute.internal)
  - Enter passwords
![Image](https://raw.githubusercontent.com/abajwa-hw/security-workshops/master/screenshots/ranger-213-setup/ranger-213-1.png)
![Image](https://raw.githubusercontent.com/abajwa-hw/security-workshops/master/screenshots/ranger-213-setup/ranger-213-2.png)

2. Ranger User info tab
  - 'Sync Source' = AD/LDAP 
  - Common configs subtab
    - Enter password
![Image](https://raw.githubusercontent.com/abajwa-hw/security-workshops/master/screenshots/ranger-213-setup/ranger-213-3.png)
![Image](https://raw.githubusercontent.com/abajwa-hw/security-workshops/master/screenshots/ranger-213-setup/ranger-213-3.5.png)

3. Ranger User info tab 
  - User configs subtab
    - User Search Base = `ou=CorpUsers,dc=lab,dc=hortonworks,dc=net`
    - User Search Filter = `(objectcategory=person)`
![Image](https://raw.githubusercontent.com/abajwa-hw/security-workshops/master/screenshots/ranger-213-setup/ranger-213-4.png)
![Image](https://raw.githubusercontent.com/abajwa-hw/security-workshops/master/screenshots/ranger-213-setup/ranger-213-5.png)

4. Ranger User info tab 
  - Group configs subtab
    - No changes needed
![Image](https://raw.githubusercontent.com/abajwa-hw/security-workshops/master/screenshots/ranger-213-setup/ranger-213-6.png)

5. Ranger plugins tab
  - Enable all plugins
![Image](https://raw.githubusercontent.com/abajwa-hw/security-workshops/master/screenshots/ranger-213-setup/ranger-213-7.png)

6. Ranger Audits tab 
  - SolrCloud = ON
  - enter password
![Image](https://raw.githubusercontent.com/abajwa-hw/security-workshops/master/screenshots/ranger-213-setup/ranger-213-8.png)
![Image](https://raw.githubusercontent.com/abajwa-hw/security-workshops/master/screenshots/ranger-213-setup/ranger-213-9.png)

7.Advanced tab
  - No changes needed (skipping configuring Ranger authentication against AD for now)
![Image](https://raw.githubusercontent.com/abajwa-hw/security-workshops/master/screenshots/ranger-213-setup/ranger-213-10.png)

- On Configure Identities page, you will have to enter your AD admin credentials:
  - Admin principal: hadoopadmin@LAB.HORTONWORKS.NET
  - Admin password: BadPass#1
  
- Click Next > Deploy to install Ranger

- Once installed, restart components that require restart (e.g. HDFS, YARN, Hive etc)

- (Optional) In case of failure (usually caused by incorrectly entering the Mysql nodes FQDN in the config above), run below from Ambari node to delete the service so you can try again:
```
export SERVICE=RANGER
export AMBARI_HOST=localhost
export PASSWORD=BadPass#1
output=`curl -u hadoopadmin:$PASSWORD -i -H 'X-Requested-By: ambari'  http://localhost:8080/api/v1/clusters`
CLUSTER=`echo $output | sed -n 's/.*"cluster_name" : "\([^\"]*\)".*/\1/p'`

#attempt to unregister the service
curl -u admin:$PASSWORD -i -H 'X-Requested-By: ambari' -X DELETE http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER/services/$SERVICE

#in case the unregister service resulted in 500 error, run the below first and then retry the unregister API
#curl -u admin:$PASSWORD -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop $SERVICE via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER/services/$SERVICE

sudo service ambari-server restart

#restart agents on all nodes
sudo service ambari-agent restart
```

##### Check Ranger

- Open Ranger UI at http://RANGERHOST_PUBLIC_IP:6080
- Confirm users/group sync from AD are working by clicking 'Settings' > 'Users/Groups tab' and noticing AD users/groups are present
- Confirm that repos for HDFS, YARN, Hive etc appear under 'Access Manager tab'
- Confirm that plugins for HDFS, YARN, Hive etc appear under 'Plugins' tab 
- Confirm that audits appear under 'Audit' tab
- Confirm HDFS audits working by querying the audits dir in HDFS:
```
sudo -u hdfs hdfs dfs -cat /ranger/audit/hdfs/*/*
```
- Confirm Solr audits working by querying Solr REST API
```
curl "http://localhost:6083/solr/ranger_audits/select?q=*%3A*&df=id&wt=csv"
```
- Confirm Banana dashboard has start to show HDFS audits
http://PUBLIC_IP_OF_BANANA_NODE:6083/solr/banana/index.html#/dashboard

**TODO** add screenshots

------------------

# Lab 6

## Ranger KMS/Data encryption setup


- Reference: [docs](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.4/bk_Ranger_KMS_Admin_Guide/content/ch_ranger_kms_overview.html):

- Open Ambari >> start 'Add service' wizard >> select 'Ranger KMS'.
- Keep the default configs except for below properties 
  - Advanced kms-properties
    - KMS_MASTER_KEY_PASSWORD = BadPass#1
    - REPOSIORY_CONFIG_USERNAME = keyadmin@LAB.HORTONWORKS.NET
    - REPOSIORY_CONFIG_PASSWORD = BadPass#1
    - db_host = Internal FQDN of MySQL node
    - db_password = BadPass#1
    - db_root_password = BadPass#1
  - advanced kms-site:
    - hadoop.kms.authentication.type=kerberos
    - hadoop.kms.authentication.kerberos.keytab=/etc/security/keytabs/spnego.service.keytab
    - hadoop.kms.authentication.kerberos.principal=*  
    
  - Custom kms-site (to avoid adding one at a time, you can use 'bulk add' mode):
      - hadoop.kms.proxyuser.hive.users=*
      - hadoop.kms.proxyuser.oozie.users=*
      - hadoop.kms.proxyuser.HTTP.users=*
      - hadoop.kms.proxyuser.ambari.users=*
      - hadoop.kms.proxyuser.yarn.users=*
      - hadoop.kms.proxyuser.hive.hosts=*
      - hadoop.kms.proxyuser.oozie.hosts=*
      - hadoop.kms.proxyuser.HTTP.hosts=*
      - hadoop.kms.proxyuser.ambari.hosts=*
      - hadoop.kms.proxyuser.yarn.hosts=*    
      - hadoop.kms.proxyuser.keyadmin.groups=*
      - hadoop.kms.proxyuser.keyadmin.hosts=*
      - hadoop.kms.proxyuser.keyadmin.users=*      
        ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ambari-KMS-proxy.png) 
  - Advanced ranger-kms-audit:
    - Audit to Solr
    - Audit to HDFS
    - For xasecure.audit.destination.hdfs.dir, replace NAMENODE_HOSTNAME with FQDN of host where name node is running e.g.
      - xasecure.audit.destination.hdfs.dir = hdfs://ip-172-30-0-185.us-west-2.compute.internal:8020/ranger/audit

- Click Next to proceed with the wizard

- On Configure Identities page, you will have to enter your AD admin credentials:
  - Admin principal: hadoopadmin@LAB.HORTONWORKS.NET
  - Admin password: BadPass#1
  
- Click Next > Deploy to install RangerKMS
        
- Restart Ranger and RangerKMS via Ambari (hold off on restarting HDFS for now)

- On RangerKMS node, create symlink to core-site.xml
```
sudo ln -s /etc/hadoop/conf/core-site.xml /etc/ranger/kms/conf/core-site.xml
```

- Confirm these properties got populated to kms://http@<kmshostname>:9292/kms
  - HDFS > Configs > Advanced core-site:
    - hadoop.security.key.provider.path
  - HDFS > Configs > Advanced hdfs-site:
    - dfs.encryption.key.provider.uri  
    
- Set the KMS proxy user
  - HDFS > Configs > Custom core-site:
    - hadoop.proxyuser.kms.groups = *   

- Restart the HDFS and Ranger and RangerKMS service.


## Ranger KMS/Data encryption exercise

- Login to Ranger as admin/admin and 
  - create new user nn
    - Settings > Users/Groups > Add new user
      - username = nn
      - password = BadPass#1
      - First name = namenode
      - Role: User
      - Group: hadoop-admins
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-add-nn.png) 
    - Similarly, create a user: HTTP  
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-user-HTTP.png)
  
  - Now lets add hadoopadmin to 'global policy' for HDFS to allow the user to global access on HDFS
    - Access Manager > HDFS > (clustername)_hadoop 
    ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-HDFS-policy.png)
    - This will open the list of HDFS policies
    ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-HDFS-edit-policy.png)
    - Edit the 'global' policy (the first one) and add hadoopadmin to global HDFS policy and Save 
    ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-HDFS-edit-policy-add-hadoopadmin.png)
  
  - Now add a new policy for HTTP user to write KMS audits to HDFS by clicking "Add new policy" and creating below policy:
    - name: kms audits
    - resource path: /ranger/audit/kms
    - user: HTTP
    - Permissions: Read Write Execute
    ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-policy-kms-audit.png) 
    
- Logout of Ranger
  - Top right > admin > Logout      
- Login to Ranger as keyadmin/keyadmin
- Confirm the KMS repo was setup correctly
  - Under Service Manager > KMS > Click the Edit icon (next to the trash icon) to edit the KMS repo
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-KMS-edit-repo.png) 
  - Click 'Test connection' 
  - if it fails re-enter below fields and re-try:
    - Username: keyadmin@LAB.HORTONWORKS.NET
    - Password: BadPass#1
  - Once the test passes, click Save  
  
- Create a key called testkey - for reference: see [doc](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.4/bk_Ranger_KMS_Admin_Guide/content/ch_use_ranger_kms.html)
  - Select Encryption > Key Manager
  - Select KMS service > pick your kms > Add new Key
    - if an error is thrown, go back and test connection as described in previous step
  - Create a key called `testkey` > Save
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-KMS-createkey.png)
  
- Add user hadoopadmin and nn to default KMS key policy
  - Click Access Manager tab
  - Click Service Manager > KMS > (clustername)_kms link
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-KMS-policy.png)

  - Edit the default policy
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-KMS-edit-policy.png)
  
  - Under 'Select User', Add hadoopadmin and nn users and click Save
   ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-KMS-policy-add-nn.png)
  
  
- Run below to create a zone using the key and perform basic key and EZ exercises 
  - Create EZ using key
  - Copy file to EZ
  - Delete file from EZ
  - View contents for raw file
  - Prevent access to raw file
  - **TODO** copy file across EZs
  - **TODO** move hive warehouse dir to EZ
  
```

#run kinit as different users: hdfs, hadoopadmin, sales1

export PASSWORD=BadPass#1

#detect name of cluster
output=`curl -u hadoopadmin:$PASSWORD -i -H 'X-Requested-By: ambari'  http://localhost:8080/api/v1/clusters`
cluster=`echo $output | sed -n 's/.*"cluster_name" : "\([^\"]*\)".*/\1/p'`

#then kinit using the keytab and the principal name
sudo -u hdfs kinit -kt /etc/security/keytabs/hdfs.headless.keytab hdfs-${cluster}

#kinit as hadoopadmin and sales using BadPass#1 
sudo -u hadoopadmin kinit
sudo -u sales1 kinit

#as hadoopadmin create dir
sudo -u hadoopadmin hdfs dfs -mkdir /zone_encr

#as hdfs create/list EZ
sudo -u hdfs hdfs crypto -createZone -keyName testkey -path /zone_encr
# if you get 'RemoteException' error it means you have not given namenode user permissions on testkey by creating a policy for KMS in Ranger

#check it got created
sudo -u hdfs hdfs crypto -listZones  

#create test file
sudo -u hadoopadmin echo "My test file1" > /tmp/test1.log
sudo -u hadoopadmin echo "My test file2" > /tmp/test2.log

#copy file to EZ
sudo -u hadoopadmin hdfs dfs -copyFromLocal /tmp/test1.log /zone_encr
sudo -u hadoopadmin hdfs dfs -copyFromLocal /tmp/test2.log /zone_encr

#Notice that hadoopadmin allowed to decrypt EEK but not sales user
sudo -u hadoopadmin hdfs dfs -cat /zone_encr/test1.log
#this should work

sudo -u sales1      hdfs dfs -cat /zone_encr/test1.log
## this should give you below error
## cat: User:sales1 not allowed to do 'DECRYPT_EEK' on 'testkey'

#delete a file from EZ - note the skipTrash option
sudo -u hadoopadmin hdfs dfs -rm -skipTrash /zone_encr/test2.log

#View contents of raw file in encrypted zone as hdfs super user. This should show some encrypted chacaters
sudo -u hdfs hdfs dfs -cat /.reserved/raw/zone_encr/test1.log

#Prevent user hdfs from reading the file by setting security.hdfs.unreadable.by.superuser attribute. Note that this attribute can only be set on files and can never be removed.
sudo -u hdfs hdfs dfs -setfattr -n security.hdfs.unreadable.by.superuser  /.reserved/raw/zone_encr/test1.log

# Now as hdfs super user, try to read the files or the contents of the raw file
sudo -u hdfs hdfs dfs -cat /.reserved/raw/zone_encr/test1.log

## You should get below error
##cat: Access is denied for hdfs since the superuser is not allowed to perform this operation.

```


------------------

# Lab 7

## Secured Hadoop exercises

#### Access secured HDFS

- Goal: Create a /sales dir in HDFS and ensure only users belonging to sales group (and admins) have access
 
- Confirm the HDFS repo was setup correctly in Ranger
  - In Ranger > Under Service Manager > HDFS > Click the Edit icon (next to the trash icon) to edit the HDFS repo
  - Click 'Test connection' 
  - if it fails re-enter below fields and re-try:
    - Username: rangeradmin@LAB.HORTONWORKS.NET
    - Password: BadPass#1
  - Once the test passes, click Save  
  
   
- Create /sales dir in HDFS as hadoopadmin
```
#authenticate
sudo -u hadoopadmin kinit
# enter password: BadPass#1

#create dir and set permissions to 000
sudo -u hadoopadmin hadoop fs -mkdir /sales
sudo -u hadoopadmin hadoop fs -chmod 000 /sales
```  

- Now login as sales1 and attempt to access it before adding any Ranger HDFS policy
```
sudo su - sales1

hdfs dfs -ls /sales
```
- This fails with `GSSException: No valid credentials provided` because the cluster is kerborized and we have not authenticated yet

- Authenticate as sales1 user and check the ticket
```
kinit
# enter password: BadPass#1

klist
## Default principal: sales1@LAB.HORTONWORKS.NET
```
- Now try accessing the dir again as sales1
```
hdfs dfs -ls /sales
```
- This time it fails with authorization error: 
  - `Permission denied: user=sales1, access=READ_EXECUTE, inode="/sales":hadoopadmin:hdfs:d---------`

- Login into Ranger UI e.g. at http://RANGER_HOST_PUBLIC_IP:6080/index.html as admin/admin

- In Ranger, click on 'Audit' to open the Audits page and filter by below. 
  - Service Type: `HDFS`
  - User: `sales1`
  
- Notice that Ranger captured the access attempt and since there is currently no policy to allow the access, it was `Denied`
![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-audit-HDFS-denied.png)

- To create an HDFS Policy in Ranger, follow below steps:
  - On the 'Access Manager' tab click HDFS > (clustername)_hadoop
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-HDFS-policy.png)
  - This will open the list of HDFS policies
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-HDFS-edit-policy.png)
  - Click 'Add New Policy' button to create a new one allowing `sales` group users access to `/sales` dir:
    - Policy Name: `sales dir`
    - Resource Path: `/sales`
    - Group: `sales`
    - Permissions : `Execute Read Write`
    - Add
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-HDFS-create-policy.png)
  
- Now try accessing the dir again as sales1 and now there is no error seen
```
hdfs dfs -ls /sales
```

- In Ranger, click on 'Audit' to open the Audits page and filter by below:
  - Service Type: HDFS
  - User: sales1
  
- Notice that Ranger captured the access attempt and since this time there is a policy to allow the access, it was `Allowed`
![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-audit-HDFS-allowed.png)  

  - You can also see the details that were captured for each request:
    - Policy that allowed the access
    - Time
    - Requesting user
    - Service type (e.g. hdfs, hive, hbase etc)
    - Resource name 
    - Access type (e.g. read, write, execute)
    - Result (e.g. allowed or denied)
    - Access enforcer (i.e. whether native acl or ranger acls were used)
    - Client IP
    - Event count
    
- For any allowed requests, notice that you can quickly check the details of the policy that allowed the access by clicking on the policy number in the 'Policy ID' column
![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-audit-policy-details.png)  

- Now let's check whether non-sales users can access the directory

- Logout as sales1 and log back in as hr1
```
kdestroy
#logout as sales1
logout

#login as hr1 and authenticate
sudo su - hr1

kinit
# enter password: BadPass#1

klist
## Default principal: hr1@LAB.HORTONWORKS.NET
```
- Try to access the same dir as hr1 and notice it fails
```
hdfs dfs -ls /sales
## ls: Permission denied: user=hr1, access=READ_EXECUTE, inode="/sales":hadoopadmin:hdfs:d---------
```

- In Ranger, click on 'Audit' to open the Audits page and this time filter by 'Resource Name'
  - Service Type: `HDFS`
  - Resource Name: `/sales`
  
- Notice you can see the history/details of all the requests made for /sales directory:
  - created by hadoopadmin 
  - initial request by sales1 user was denied 
  - subsequent request by sales1 user was allowed (once the policy was created)
  - request by hr1 user was denied
![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-audit-HDFS-summary.png)  

- Logout as hr1
```
kdestroy
logout
```
- We have successfully setup an HDFS dir which is only accessible by sales group (and admins)

#### Access secured Hive

- Goal: Setup Hive authorization policies to ensure sales users only have access to code, description columns in default.sample_07

- Confirm the HIVE repo was setup correctly in Ranger
  - In Ranger > Service Manager > HIVE > Click the Edit icon (next to the trash icon) to edit the HIVE repo
  - Click 'Test connection' 
  - if it fails re-enter below fields and re-try:
    - Username: rangeradmin@LAB.HORTONWORKS.NET
    - Password: BadPass#1
  - Once the test passes, click Save  

- Run these steps from node where Hive (or client) is installed 

- Login as sales1 and attempt to connect to default database in Hive via beeline and access sample_07 table

- Notice that in the JDBC connect string for connecting to an secured Hive while its running in default (ie binary) transport mode :
  - port remains 10000
  - *now a kerberos principal needs to be passed in*

```
sudo su - sales1

beeline -u "jdbc:hive2://localhost:10000/default;principal=hive/$(hostname -f)@HORTONWORKS.COM"
```
- This fails with `GSS initiate failed` because the cluster is kerborized and we have not authenticated yet

- To exit beeline:
```
!q
```
- Authenticate as sales1 user and check the ticket
```
kinit
# enter password: BadPass#1

klist
## Default principal: sales1@LAB.HORTONWORKS.NET
```
- Now try connect to Hive via beeline as sales1
```
beeline -u "jdbc:hive2://localhost:10000/default;principal=hive/$(hostname -f)@HORTONWORKS.COM"
```
- This time it connects. Now try to run a query
```
beeline> select code, description from sample_07;
```
- Now it fails with authorization error: 
  - `HiveAccessControlException Permission denied: user [sales1] does not have [SELECT] privilege on [default/sample_07]`

- Login into Ranger UI e.g. at http://RANGER_HOST_PUBLIC_IP:6080/index.html as admin/admin

- In Ranger, click on 'Audit' to open the Audits page and filter by below. 
  - Service Type: `Hive`
  - User: `sales1`
  
- Notice that Ranger captured the access attempt and since there is currently no policy to allow the access, it was `Denied`
![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-audit-HIVE-denied.png)

- To create an HIVE Policy in Ranger, follow below steps:
  - On the 'Access Manager' tab click HIVE > (clustername)_hive
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-HIVE-policy.png)
  - This will open the list of HIVE policies
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-HIVE-edit-policy.png)
  - Click 'Add New Policy' button to create a new one allowing `sales` group users access to `code` and `description` columns in `sample_07` dir:
    - Policy Name: `sample_07`
    - Hive Database: `default`
    - table: `sample_07`
    - Hive Column: `code` `description`
    - Group: `sales`
    - Permissions : `select`
    - Add
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-HIVE-create-policy.png)
  
- Now try accessing the columns again and now the query works
```
beeline> select code, description from sample_07;
```

- Note though, that if instead you try to describe the table or query all columns, it will be denied - because we only gave sales users access to two columns in the table
  - `beeline> desc sample_07;`
  - `beeline> select * from sample_07;`
  
- In Ranger, click on 'Audit' to open the Audits page and filter by below:
  - Service Type: HIVE
  - User: sales1
  
- Notice that Ranger captured the access attempt and since this time there is a policy to allow the access, it was `Allowed`
![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-audit-HIVE-allowed.png)  

  - You can also see the details that were captured for each request:
    - Policy that allowed the access
    - Time
    - Requesting user
    - Service type (e.g. hdfs, hive, hbase etc)
    - Resource name 
    - Access type (e.g. read, write, execute)
    - Result (e.g. allowed or denied)
    - Access enforcer (i.e. whether native acl or ranger acls were used)
    - Client IP
    - Event count
    
- For any allowed requests, notice that you can quickly check the details of the policy that allowed the access by clicking on the policy number in the 'Policy ID' column
![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-audit-HIVE-policy-details.png)  

- Now let's check whether non-sales users can access the table

- Logout as sales1 and log back in as hr1
```
kdestroy
#logout as sales1
logout

#login as hr1 and authenticate
sudo su - hr1

kinit
# enter password: BadPass#1

klist
## Default principal: hr1@LAB.HORTONWORKS.NET
```
- Try to access the same dir as hr1 and notice it fails
```
beeline -u "jdbc:hive2://localhost:10000/default;principal=hive/$(hostname -f)@HORTONWORKS.COM"
```
```
beeline> select code, description from sample_07;
```
- In Ranger, click on 'Audit' to open the Audits page and filter by 'Service Type' = 'Hive'
  - Service Type: `HIVE`

  
- Here you can see the request by sales1 was allowed but hr1 was denied

![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-audit-HIVE-summary.png)  

- Quit beeline
```
!q
```

- Logout as hr1
```
kdestroy
logout
```
- We have setup Hive authorization policies to ensure only sales users have access to code, description columns in default.sample_07


#### Access secured HBase

- Goal: Create a table called 'sales' in HBase and setup authorization policies to ensure only sales users have access to the table

- Confirm the HBASE repo was setup correctly in Ranger
  - In Ranger > Service Manager > HBASE > Click the Edit icon (next to the trash icon) to edit the HBASE repo
  - Click 'Test connection' 
  - if it fails re-enter below fields and re-try:
    - Username: rangeradmin@LAB.HORTONWORKS.NET
    - Password: BadPass#1
  - Once the test passes, click Save  
  
- Run these steps from any node where Hbase Master or RegionServer services are installed 

- Login as sales1
```
sudo su - sales1
```
-  Start the hbase shell
```
hbase shell
```
- List tables in default database
```
hbase> list 'default'
```
- This fails with `GSSException: No valid credentials provided` because the cluster is kerborized and we have not authenticated yet

- To exit hbase shell:
```
exit
```
- Authenticate as sales1 user and check the ticket
```
kinit
# enter password: BadPass#1

klist
## Default principal: sales1@LAB.HORTONWORKS.NET
```
- Now try connect to Hbase shell and list tables as sales1
```
hbase shell
hbase> list 'default'
```
- This time it works. Now try to create a table called `sales` with column family called `cf`
```
hbase> create 'sales', 'cf'
```
- Now it fails with authorization error: 
  - `org.apache.hadoop.hbase.security.AccessDeniedException: Insufficient permissions for user 'sales1@LAB.HORTONWORKS.NET' (action=create)`

- Login into Ranger UI e.g. at http://RANGER_HOST_PUBLIC_IP:6080/index.html as admin/admin

- In Ranger, click on 'Audit' to open the Audits page and filter by below. 
  - Service Type: `Hbase`
  - User: `sales1`
  
- Notice that Ranger captured the access attempt and since there is currently no policy to allow the access, it was `Denied`
![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-audit-HBASE-denied.png)

- To create an HBASE Policy in Ranger, follow below steps:
  - On the 'Access Manager' tab click HBASE > (clustername)_hbase
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-HBASE-policy.png)
  - This will open the list of HBASE policies
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-HBASE-edit-policy.png)
  - Click 'Add New Policy' button to create a new one allowing `sales` group users access to `code` and `description` columns in `sample_07` dir:
    - Policy Name: `sales`
    - Hbase Table: `sales`
    - Hbase Column Family: `*`
    - Hbase Column: `*`
    - Group : `sales`    
    - Permissions : `Admin` `Create` `Read` `Write`
    - Add
  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-HBASE-create-policy.png)
  
- Now try creating the table and now it works
```
hbase> create 'sales', 'cf'
```
  
- In Ranger, click on 'Audit' to open the Audits page and filter by below:
  - Service Type: HBASE
  - User: sales1
  
- Notice that Ranger captured the access attempt and since this time there is a policy to allow the access, it was `Allowed`
![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-audit-HBASE-allowed.png)  

  - You can also see the details that were captured for each request:
    - Policy that allowed the access
    - Time
    - Requesting user
    - Service type (e.g. hdfs, hive, hbase etc)
    - Resource name 
    - Access type (e.g. read, write, execute)
    - Result (e.g. allowed or denied)
    - Access enforcer (i.e. whether native acl or ranger acls were used)
    - Client IP
    - Event count
    
- For any allowed requests, notice that you can quickly check the details of the policy that allowed the access by clicking on the policy number in the 'Policy ID' column
![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-audit-HBASE-policy-details.png)  

- Exit hbase shell
```
hbase> exit
```

- Now let's check whether non-sales users can access the table

- Logout as sales1 and log back in as hr1
```
kdestroy
#logout as sales1
logout

#login as hr1 and authenticate
sudo su - hr1

kinit
# enter password: BadPass#1

klist
## Default principal: hr1@LAB.HORTONWORKS.NET
```
- Try to access the same dir as hr1 and notice this user does not even see the table
```
hbase shell
hbase> describe 'sales'
hbase> list 'default'
```
- Try to create a table as hr1 and it fails with `org.apache.hadoop.hbase.security.AccessDeniedException: Insufficient permissions`
```
hbase> create 'sales', 'cf'
```
- In Ranger, click on 'Audit' to open the Audits page and filter by:
  - Service Type: `HBASE`
  - Resource Name: `sales`

- Here you can see the request by sales1 was allowed but hr1 was denied

![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-audit-HBASE-summary.png)  

- Exit hbase shell
```
hbase> exit
```

- Logout as hr1
```
kdestroy
logout
```
- We have successfully created a table called 'sales' in HBase and setup authorization policies to ensure only sales users have access to the table

- This shows how you can interact with Hadoop components on kerborized cluster and use Ranger to manage authorization policies and audits

- At this point your Silk/Banana audit dashboard should show audit data from multiple Hadoop components e.g. http://54.68.246.157:6083/solr/banana/index.html#/dashboard

![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-audit-banana.png)  


#### (Optional) Use Sqoop to import 

- If Sqoop is not already installed, install it via Ambari on same node where Mysql/Hive are installed:
  - Admin > Stacks and Versions > Sqoop > Add service > select node where Mysql/Hive are installed and accept all defaults
  
- Login as root, and download a sample csv and login to Mysql
```
sudo su - 
wget https://raw.githubusercontent.com/abajwa-hw/single-view-demo/master/data/PII_data_small.csv
mysql -u root -pBadPass#1
```

- At the `mysql>` prompt, run below to create a table in Mysql, import the data from csv and test that it was created:
```
create database people;
use people;
create table persons (people_id INT PRIMARY KEY, sex text, bdate DATE, firstname text, lastname text, addresslineone text, addresslinetwo text, city text, postalcode text, ssn text, id2 text, email text, id3 text);
LOAD DATA LOCAL INFILE '~/PII_data_small.csv' REPLACE INTO TABLE persons FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n';

select people_id, firstname, lastname, city from persons where lastname='SMITH';
```

- logoff as root
```
logoff
```

- Create Ranger policy to allow sales group all permissions on persons table in Hive
  - Access Manager > Hive > (cluster)_hive > Add new policy
  - Create new policy as below and click Add:
![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-HIVE-create-policy-persons.png)  

- Login as sales1
```
sudo su - sales1
```

- As sales1 user, kinit and run sqoop job to create persons table in Hive (in ORC format) and import data
```
kinit
## enter BadPass#1 as password

sqoop import --verbose --connect 'jdbc:mysql://localhost/people' --table persons --username root --password BadPass#1 --hcatalog-table persons --hcatalog-storage-stanza "stored as orc" -m 1 --create-hcatalog-table  --driver com.mysql.jdbc.Driver
```
- Login to beeline
```
beeline -u "jdbc:hive2://localhost:10000/default;principal=hive/$(hostname -f)@HORTONWORKS.COM"
```

- Query persons table in beeline
```
beeline> select * from persons;
```
- Now that the authorization policy is in place, the query should work

- Ranger audit should show the request was allowed:
  - Under Ranger > Audit > query for
    - Service type: HIVE
![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-HIVE-audit-persons.png)

- You have now interacted with Hadoop components in secured mode and used Ranger to manage authorization policies and audits

------------------

# Lab 8

## Knox 

### Knox Configuration 

#### Knox Configuration for AD authentication
 
- Run these steps on the node where Knox was installed earlier
- Create keystore alias for the ldap manager user (which you set in 'systemUsername' in the topology) e.g. BadPass#1
   - Read password for use in following command (this will prompt you for a password and save it in knoxpass environment variable):
   ```
   read -s -p "Password: " knoxpass
   ```
  - This is a handy way to set an env var without storing the command in your history

   - Create password alias for Knox called knoxLdapSystemPassword
   ```
   sudo sudo -u knox /usr/hdp/current/knox-server/bin/knoxcli.sh create-alias knoxLdapSystemPassword --cluster default --value ${knoxpass}
   unset knoxpass
   ```
  
- Now lets configure Knox to use our AD for authentication. Replace below content in Ambari > Knox > Config > Advanced topology. Then restart Knox
  - How to tell what configs were changed from defaults? 
    - Default configs remain indented below
    - Configurations that were added/modified are not indented
```
        <topology>

            <gateway>

                <provider>
                    <role>authentication</role>
                    <name>ShiroProvider</name>
                    <enabled>true</enabled>
                    <param>
                        <name>sessionTimeout</name>
                        <value>30</value>
                    </param>
                    <param>
                        <name>main.ldapRealm</name>
                        <value>org.apache.hadoop.gateway.shirorealm.KnoxLdapRealm</value> 
                    </param>

<!-- changes for AD/user sync -->

<param>
    <name>main.ldapContextFactory</name>
    <value>org.apache.hadoop.gateway.shirorealm.KnoxLdapContextFactory</value>
</param>

<!-- main.ldapRealm.contextFactory needs to be placed before other main.ldapRealm.contextFactory* entries  -->
<param>
    <name>main.ldapRealm.contextFactory</name>
    <value>$ldapContextFactory</value>
</param>

<!-- AD url -->
<param>
    <name>main.ldapRealm.contextFactory.url</name>
    <value>ldap://ad01.lab.hortonworks.net:389</value> 
</param>

<!-- system user -->
<param>
    <name>main.ldapRealm.contextFactory.systemUsername</name>
    <value>cn=ldap-reader,ou=ServiceUsers,dc=lab,dc=hortonworks,dc=net</value>
</param>

<!-- pass in the password using the alias created earlier -->
<param>
    <name>main.ldapRealm.contextFactory.systemPassword</name>
    <value>${ALIAS=knoxLdapSystemPassword}</value>
</param>

                    <param>
                        <name>main.ldapRealm.contextFactory.authenticationMechanism</name>
                        <value>simple</value>
                    </param>
                    <param>
                        <name>urls./**</name>
                        <value>authcBasic</value> 
                    </param>

<!--  AD groups of users to allow -->
<param>
    <name>main.ldapRealm.searchBase</name>
    <value>ou=CorpUsers,dc=lab,dc=hortonworks,dc=net</value>
</param>
<param>
    <name>main.ldapRealm.userObjectClass</name>
    <value>person</value>
</param>
<param>
    <name>main.ldapRealm.userSearchAttributeName</name>
    <value>sAMAccountName</value>
</param>

<!-- changes needed for group sync-->
<param>
    <name>main.ldapRealm.authorizationEnabled</name>
    <value>true</value>
</param>
<param>
    <name>main.ldapRealm.groupSearchBase</name>
    <value>ou=CorpUsers,dc=lab,dc=hortonworks,dc=net</value>
</param>
<param>
    <name>main.ldapRealm.groupObjectClass</name>
    <value>group</value>
</param>
<param>
    <name>main.ldapRealm.groupIdAttribute</name>
    <value>cn</value>
</param>


                </provider>

                <provider>
                    <role>identity-assertion</role>
                    <name>Default</name>
                    <enabled>true</enabled>
                </provider>

                <provider>
                    <role>authorization</role>
                    <name>XASecurePDPKnox</name>
                    <enabled>true</enabled>
                </provider>

            </gateway>

            <service>
                <role>NAMENODE</role>
                <url>hdfs://{{namenode_host}}:{{namenode_rpc_port}}</url>
            </service>

            <service>
                <role>JOBTRACKER</role>
                <url>rpc://{{rm_host}}:{{jt_rpc_port}}</url>
            </service>

            <service>
                <role>WEBHDFS</role>
                <url>http://{{namenode_host}}:{{namenode_http_port}}/webhdfs</url>
            </service>

            <service>
                <role>WEBHCAT</role>
                <url>http://{{webhcat_server_host}}:{{templeton_port}}/templeton</url>
            </service>

            <service>
                <role>OOZIE</role>
                <url>http://{{oozie_server_host}}:{{oozie_server_port}}/oozie</url>
            </service>

            <service>
                <role>WEBHBASE</role>
                <url>http://{{hbase_master_host}}:{{hbase_master_port}}</url>
            </service>

            <service>
                <role>HIVE</role>
                <url>http://{{hive_server_host}}:{{hive_http_port}}/{{hive_http_path}}</url>
            </service>

            <service>
                <role>RESOURCEMANAGER</role>
                <url>http://{{rm_host}}:{{rm_port}}/ws</url>
            </service>
        </topology>
```

#### HDFS Configuration for Knox

-  Tell Hadoop to allow our users to access Knox from any node of the cluster. Make the below change in Ambari > HDFS > Config > Custom core-site 
  - hadoop.proxyuser.knox.groups=users,hadoop-admins,sales,hr,legal
  - hadoop.proxyuser.knox.hosts=*
    - (better would be to put a comma separated list of the FQDNs of the hosts)
  - Now restart HDFS
  - Without this step you will see an error like below when you run the WebHDFS request later on:
  ```
   org.apache.hadoop.security.authorize.AuthorizationException: User: knox is not allowed to impersonate sales1"
  ```


#### Ranger Configuration for Knox

- Confirm the KNOX repo was setup correctly in Ranger
  - In Ranger > Service Manager > KNOX > Click the Edit icon (next to the trash icon) to edit the KNOX repo
  - Click 'Test connection' 
  - if it fails re-enter below fields and re-try:
    - Username: rangeradmin@LAB.HORTONWORKS.NET
    - Password: BadPass#1
  - Once the test passes, click Save  
  
- Setup a Knox policy for sales group for WEBHDFS by:
- Login to Ranger > Access Manager > KNOX > click the cluster name link > Add new policy
  - Policy name: webhdfs
  - Topology name: default
  - Service name: WEBHDFS
  - Group permissions: sales 
  - Permission: check Allow
  - Add

  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-knox-webhdfs-policy.png)

#### WebHDFS over Knox exercises 

- Now we can post some requests to WebHDFS over Knox to check its working. We will use curl with following arguments:
  - -i (aka –include): used to output HTTP response header information. This will be important when the content of the HTTP Location header is required for subsequent requests.
  - -k (aka –insecure) is used to avoid any issues resulting from the use of demonstration SSL certificates.
  - -u (aka –user) is used to provide the credentials to be used when the client is challenged by the gateway.
  - Note that most of the samples do not use the cookie features of cURL for the sake of simplicity. Therefore we will pass in user credentials with each curl request to authenticate.

- Opening terminal to host where Knox is running and send below curl request to 8443 port where Knox is running to run `ls` command on `/` dir in HDFS:
```
curl -ik -u sales1:BadPass#1 https://localhost:8443/gateway/default/webhdfs/v1/?op=LISTSTATUS
```
  - This should return json object containing list of dirs/files located in root dir and their attributes
  
- Try the same request as hr1 and notice it fails with `Error 403 Forbidden` :
  - This is expected since in the policy above, we only allowed sales group to access WebHDFS over Knox
```
curl -ik -u sales1:BadPass#1 https://localhost:8443/gateway/default/webhdfs/v1/?op=LISTSTATUS
```

- Notice that to make the requests over Knox, a kerberos ticket is not needed - the user authenticates by passing in AD/LDAP credentials

- Check in Ranger Audits to confirm the requests were audited:
  - Ranger > Audit > Service type: KNOX

  ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/Ranger-knox-webhdfs-audit.png)


- Other things to access WebHDFS with Knox

  - 1. Use cookie to make request without passing in credentials
    - When you ran the previous curl request it would have listed HTTP headers as part of output. One of the headers will be 'Set Cookie'
    - e.g. `Set-Cookie: JSESSIONID=xxxxxxxxxxxxxxx;Path=/gateway/default;Secure;HttpOnly`
    - You can pass in the value from your setup and make the request without passing in credentials:
  ```
  curl -ik --cookie "JSESSIONID=xxxxxxxxxxxxxxx;Path=/gateway/default;Secure;HttpOnly" -X GET https://localhost:8443/gateway/default/webhdfs/v1/?op=LISTSTATUS
  ```
  
  - 2. Open file via WebHDFS
    - List files under /tmp and pick a text file to open:
    ```
    curl -ik -u sales1:BadPass#1 https://localhost:8443/gateway/default/webhdfs/v1/tmp?op=LISTSTATUS
    ```
      - You can run below command to find a test file
      
      ```
      hdfs dfs -ls /tmp/idtest.ambari-qa.*.in
      ```
      - In our case this returned a file called `/tmp/idtest.ambari-qa.1454448964.64.in`
      
    - Open this file via WebHDFS 
    ```
    curl -ik -u sales1:BadPass#1 -X GET https://localhost:8443/gateway/default/webhdfs/v1/tmp/idtest.ambari-qa.1454448964.64.in?op=OPEN
    ```
      - Look at value of Location header. This will contain a long url 
      ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/knox-location.png)
            
    - Access contents of file /tmp/idtest.ambari-qa.1454448964.64.in by passing the value from the above Location header
    ```
    curl -ik -u sales1:BadPass#1 -X GET '{https://localhost:8443/gateway/default/webhdfs/data/v1/webhdfs/v1/tmp/idtest.ambari-qa.1454448964.64.in?_=AAAACAAAABAAAAEwvyZNDLGGNwahMYZKvaHHaxymBy1YEoe4UCQOqLC7o8fg0z6845kTvMQN_uULGUYGoINYhH5qafY_HjozUseNfkxyrEo313-Fwq8ISt6MKEvLqas1VEwC07-ihmK65Uac8wT-Cmj2BDab5b7EZx9QXv29BONUuzStCGzBYCqD_OIgesHLkhAM6VNOlkgpumr6EBTuTnPTt2mYN6YqBSTX6cc6OhX73WWE6atHy-lv7aSCJ2I98z2btp8XLWWHQDmwKWSmEvtQW6Aj-JGInJQzoDAMnU2eNosdcXaiYH856zC16IfEucdb7SA_mqAymZuhm8lUCvL25hd-bd8p6mn1AZlOn92VySGp2TaaVYGwX-6L9by73bC6sIdi9iKPl3Iv13GEQZEKsTm1a96Bh6ilScmrctk3zmY4vBYp2SjHG9JRJvQgr2XzgA}'
    ```
      
  - 3. Use groovy scripts to access WebHDFS
    - Edit the groovy script to set:
      - gateway = "https://localhost:8443/gateway/default"
      - username = "sales1"
      - password = "BadPass#1"
    ```
    sudo vi /usr/hdp/current/knox-server/samples/ExampleWebHdfsLs.groovy
    ```
    - Run the script
    ```
    sudo java -jar /usr/hdp/current/knox-server/bin/shell.jar /usr/hdp/current/knox-server/samples/ExampleWebHdfsLs.groovy
    ```
    - Notice output show list of dirs in HDFS
    ```
    [app-logs, apps, ats, hdp, mapred, mr-history, ranger, tmp, user, zone_encr]
    ```
    
  - 4. Access via browser 
    - Take the same url we have been hitting via curl and replace localhost with public IP of Knox node (remember to use https!) e.g. **https**://PUBLIC_IP_OF_KNOX_HOST:8443/gateway/default/webhdfs/v1?op=LISTSTATUS
    - Open the URL via browser
    - Login as sales1/BadPass#1
    
     ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/knox-webhdfs-browser1.png)
     ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/knox-webhdfs-browser2.png)
     ![Image](https://raw.githubusercontent.com/seanorama/masterclass/master/security-advanced/screenshots/knox-webhdfs-browser3.png)
      

- We have shown how you can use Knox to avoid the end user from having to know about internal details of cluster
  - whether its kerborized or not
  - what the cluster topology is (e.g. what node WebHDFS was running)


#### Hive over Knox 
**TODO** 

##### Configure Hive for Knox

- In Ambari, under Hive > Configs > set the below and restart Hive component.
  - hive.server2.transport.mode = http
- Give users access to jks file.
  - This is only for testing since we are using a self-signed cert.
  - This only exposes the truststore, not the keys.
```
sudo chmod o+x /var/lib/knox /var/lib/knox/data* /var/lib/knox/data*/security /var/lib/knox/data*/security/keystores
sudo chmod o+r /var/lib/knox/data*/security/keystores/gateway.jks
```

##### Use Hive for Knox

- In the JDBC connect string for connecting to an secured Hive while its running in default (ie binary) transport mode :
  - *port changes to Knox's port 8443*
  - *a kerberos principal not longer needs to be passed in*
  - trust store is being passed in

```
beeline -u jdbc:hive2://localhost:8443/;ssl=true;sslTrustStore=/var/lib/knox/data/security/keystores/gateway.jks;trustStorePassword=BadPass#1;transportMode=http;httpPath=gateway/default/hive
```


------------------

# Lab 9 - Optional

## Other Security features for Ambari

- Setup views using : http://docs.hortonworks.com/HDPDocuments/Ambari-2.2.0.0/bk_ambari_views_guide/content/ch_using_ambari_views.html

- Automation to install views (**TODO** test this)
```
sudo su
git clone https://github.com/seanorama/ambari-bootstrap
cd ambari-bootstrap/extras/
export ambari_pass=BadPass#1
source ambari_functions.sh
./ambari-views/create-views.sh
```
- Restart HDFS via Ambari

    