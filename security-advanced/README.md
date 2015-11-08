# Environment notes

## Note to Hortonworkers

Find our Active Directory instance details in Google Drive. Title "infrastructure" in the Training folder.

## Accessing your Cluster

Credentials will be provided for these services:

* SSH
* Ambari

## Use your Cluster

### Configure name resolution & certificate to Active Directory

1. Add your Active Directory to /etc/hosts (if not in DNS)

   ```
echo "172.31.0.175 ad01.lab.hortonworks.net ad01" | sudo tee -a /etc/hosts
   ```

2. Add your CA certificate (if using self-signed & not already configured)

   ```
sudo yum -y install openldap-clients ca-certificates
sudo curl -sSL https://gist.githubusercontent.com/seanorama/af65099edd48879cfbe7/raw/5391337c28952816570a389064baa7bcef564feb/ca.crt \
    -o /etc/pki/ca-trust/source/anchors/hortonworks-net.crt

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

## test with
ldapsearch -W -D hadoopadmin@lab.hortonworks.net
   ```

## Active Directory environment
Enable kerberos using Ambari security wizard 

- KDC:
    - KDC host: ad01.lab.hortonworks.net
    - Realm name: LAB.HORTONWORKS.NET
    - LDAP url: ldaps://ad01.lab.hortonworks.net
    - Container DN: ou=hadoopclusters,dc=lab,dc=hortonworks,dc=net
    - Domains: us-west-2.compute.internal,.us-west-2.compute.internal
- Kadmin:
    - Kadmin host: ad01.lab.hortonworks.net
    - Admin principal: hadoopadmin@lab.hortonworks.net
    - Admin password:

## Setup AD/OS integration via SSSD
- Run below manually on each node
```
# Pre-req: give registersssd user permissions to join workstations to OU=CorpUsers (needed to run 'adcli join' successfully)

ad_user="registersssd"
ad_domain="lab.hortonworks.net"
ad_dc="ad01.lab.hortonworks.net"
ad_root="dc=lab,dc=hortonworks,dc=net"
ad_ou="ou=CorpUsers,${ad_root}"
ad_realm=${ad_domain^^}

sudo kinit ${ad_user}

sudo yum makecache fast
sudo yum -y -q install epel-release ## epel is required for adcli
sudo yum -y -q install sssd oddjob-mkhomedir authconfig sssd-krb5 sssd-ad sssd-tools libnss-sss libpam-sss 
sudo yum -y -q install adcli



sudo adcli join -v \
  --domain-controller=${ad_dc} \
  --domain-ou="${ad_ou}" \
  --login-ccache="/tmp/krb5cc_0" \
  --login-user="${ad_user}" \
  -v \
  --show-details

## todo:
##   pam, ssh, autofs should be disabled on master & data nodes
##   - we only need nss on those nodes
##   - edge nodes need the ability to login
sudo tee /etc/sssd/sssd.conf > /dev/null <<EOF
[sssd]
## master & data nodes only require nss. Edge nodes require pam.
services = nss, pam, ssh, autofs, pac
config_file_version = 2
domains = ${ad_realm}
override_space = _
[domain/${ad_realm}]
id_provider = ad
auth_provider = ad
chpass_provider = ad
#access_provider = ad
ad_server = ${ad_dc}
ldap_id_mapping = true
debug_level = 9
enumerate = true
#ldap_schema = ad
#cache_credentials = true
#ldap_group_nesting_level = 5
ldap_tls_cacertdir = /etc/pki/tls/certs
ldap_tls_cacert = /etc/pki/tls/certs/ca-bundle.crt
ldap_tls_reqcert = never
[nss]
override_shell = /bin/bash
EOF
sudo chmod 0600 /etc/sssd/sssd.conf

sudo authconfig --enablesssd --enablesssdauth --enablemkhomedir --enablelocauthorize --update

sudo chkconfig oddjobd on
sudo service oddjobd restart
sudo chkconfig sssd on
sudo service sssd restart

sudo kdestroy
```

## Setup Ambari/AD sync

1. Add your AD properties as defaults for Ambari LDAP sync  
  ```
ad_dc="ad01.lab.hortonworks.net"
ad_root="dc=lab,dc=hortonworks,dc=net"
ad_user="cn=ldapconnect,ou=ServiceUsers,dc=lab,dc=hortonworks,dc=net"

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

1. Run Ambari LDAP sync. Press enter to accept all defaults and enter password at the end
  ```
  sudo ambari-server setup-ldap
  ```

2. Reestart Ambari server and agents
  ```
   sudo ambari-server restart
   sudo ambari-agent restart
  ```
3. Run LDAP sync. When prompted for username/password enter admin/admin
  ```
  sudo ambari-server sync-ldap --all  
  ```

4. Now you should be able to login as AD users. Login as admin/admin and give ambari user Admin priviledge via 'Manage Ambari'


## Ranger install and AD integration

#### Create & confirm MySQL user 'root'

- `sudo mysql -h $(hostname -f)`
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

###### Prepare Ambari for MySQL *(or the database you want to use)*

- Add MySQL JAR to Ambari:
  - `sudo ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar`
    - If the file is not present, it is available on RHEL/CentOS with: `sudo yum -y install mysql-connector-java`


###### Install Ranger via Ambari

1. Install Ranger using Amabris 'Add Service' wizard. For now just populate the required configs
  - passwords
  - External URL: http://localhost:6080


###### Setup Ranger/AD user/group sync

1. Once Ranger is up, under Ambari > Ranger > Config, set the below and restart Ranger
```
ranger.usersync.source.impl.class ldap
ranger.usersync.ldap.searchBase dc=lab,dc=hortonworks,dc=net
ranger.usersync.ldap.user.searchbase dc=lab,dc=hortonworks,dc=net
ranger.usersync.group.searchbase dc=lab,dc=hortonworks,dc=net
ranger.usersync.ldap.binddn cn=ldapconnect,ou=ServiceUsers,ou=lab,dc=hortonworks,dc=net
ranger.usersync.ldap.ldapbindpassword BadPass#1
ranger.usersync.ldap.url ldap://ad01.lab.hortonworks.net
ranger.usersync.ldap.user.nameattribute sAMAccountName
ranger.usersync.ldap.user.searchfilter (objectcategory=person)
ranger.usersync.ldap.user.groupnameattribute memberof, ismemberof, msSFU30PosixMemberOf
ranger.usersync.group.memberattributename member
ranger.usersync.group.nameattribute cn
ranger.usersync.group.objectclass group
```
2. Check the usersyc log and Ranger UI if users/groups got synced
```
tail -f /var/log/ranger/usersync/usersync.log
```

###### Setup Ranger/AD auth

1. Enable AD users to login to Ranger by making below changes in Ambari > Ranger > Config > ranger-admin-site
```
ranger.authentication.method ACTIVE_DIRECTORY
ranger.ldap.ad.domain lab.hortonworks.net
ranger.ldap.ad.url "ldap://ad01.lab.hortonworks.net:389"
ranger.ldap.ad.base.dn "dc=lab,dc=hortonworks,dc=net"
ranger.ldap.ad.bind.dn "cn=ldapconnect,ou=ServiceUsers,ou=lab,dc=hortonworks,dc=net"
ranger.ldap.ad.referral follow
ranger.ldap.ad.bind.password "BadPass#1"
```
