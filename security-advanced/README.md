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




