#!/usr/bin/env bash

sudo yum -y install openldap-clients bind-utils krb5-workstation

ad_host="activedirectory.$(hostname -d)"
ad_host_ip=$(ping -w 1 ${ad_host} | awk 'NR==1 {print $3}' | sed 's/[()]//g')
echo "${ad_host_ip} activedirectory.hortonworks.com ${ad_host} activedirectory" | sudo tee -a /etc/hosts

sudo tee /etc/pki/ca-trust/source/anchors/activedirectory.pem > /dev/null <<-'EOF'
-----BEGIN CERTIFICATE-----
MIIDkTCCAnmgAwIBAgIQM/t6fF1rd5BNGojzl3ZUyDANBgkqhkiG9w0BAQUFADBb
MRMwEQYKCZImiZPyLGQBGRYDY29tMRswGQYKCZImiZPyLGQBGRYLaG9ydG9ud29y
a3MxJzAlBgNVBAMTHmhvcnRvbndvcmtzLUFDVElWRURJUkVDVE9SWS1DQTAeFw0x
NTA3MTcxNjA5MzFaFw0yMDA3MTcxNjE5MzFaMFsxEzARBgoJkiaJk/IsZAEZFgNj
b20xGzAZBgoJkiaJk/IsZAEZFgtob3J0b253b3JrczEnMCUGA1UEAxMeaG9ydG9u
d29ya3MtQUNUSVZFRElSRUNUT1JZLUNBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
MIIBCgKCAQEAp+hIqjxLEjGYgPkpK3+nlPBxPsdzhv58946YeVfV23/Umg+X5OZz
0RihoaV66TTFbBKG0UQfmrIHg8dsvY6bmLBkFnbMrkCrY/7KBu02m5qRPwNWfw7s
J/xDENL9J38/F99A3TOHXmUCXBpiYvJiAFHSxJ2Iw2A2cqx9ucClDbEGC/AsrDBc
SLuxliEscvLUhCQKJ0bfU34GWRkwwVFb6/tnihs0Eda3Q/zIcSK+YDQQJkr1M7CK
P7qvUECi/mZzmFvss/SX9fIuxPuFIzXyHxx/REUUQOGS6FwF9N1Le+je3fRVdmol
g69rpq6LxI4dY5edkoMyg6bb2t5Ln7hzSwIDAQABo1EwTzALBgNVHQ8EBAMCAYYw
DwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUFZF2e5d8NOcOniuGcnt6BsPn4skw
EAYJKwYBBAGCNxUBBAMCAQAwDQYJKoZIhvcNAQEFBQADggEBAGuqUBjdSvYqMNTu
keYRQUrC+gkaPh+ssVDzZEmitvABH7cfPVVsXEDOggOLleMY8eDvewHwlP5EXW20
X+A88B5YNcdVTn3jyJiKu89Xtiztkyzi9H+O/uc+XZ00aEbko8Nv3PCtqkIbFzs5
TRC/i20rmhsbDLGl6hKl2CJlGN9mS3Nb2uxRsfSWRS/OCGD69YYk2oNwOYqdq17g
vaRdNUxXojCfmNnU7mpeHSt6TBiP6I4JZ57Eg7CuIAp4PxsNX13GAOVHrQygvarH
3QZKHGyHYMxvz1A/kyqjq5GLiVOVlb7grYeHDGYwO7XlAYRAbPnxCkwzXDxXOEwd
VrC68Zc=
-----END CERTIFICATE-----
EOF

sudo update-ca-trust enable; sudo update-ca-trust extract; sudo update-ca-trust check
sudo keytool -keystore cacerts -importcert -noprompt \
  -storepass changeit -alias activedirectory -file /etc/pki/ca-trust/source/anchors/activedirectory.pem
sudo mkdir /etc/ambari-server/keys
sudo keytool -import -trustcacerts -alias root -noprompt -storepass BadPass#1 \
  -file /etc/pki/ca-trust/source/anchors/activedirectory.pem -keystore /etc/ambari-server/keys/ldapskeystore.jks


#ldapsearch -W -H ldaps://activedirectory.hortonworks.com -D sandboxadmin@hortonworks.com -b "ou=sandbox,ou=hdp,dc=hortonworks,dc=com"
sudo tee /etc/openldap/ldap.conf > /dev/null <<-'EOF'
SASL_NOCANON    on
URI ldap://activedirectory.hortonworks.com
BASE dc=hortonworks,dc=com
TLS_CACERTDIR /etc/pki/tls/certs
TLS_CACERT /etc/pki/tls/certs/ca-bundle.crt
EOF

exit

sudo tee /etc/samba/smb.conf > /dev/null <<-EOF
[Global]
  netbios name = $(hostname -s)
  workgroup = HORTONWORKS
  realm = HORTONWORKS.COM
  server string = %h HDP Host
  security = ads
  encrypt passwords = yes
  password server = activedirectory.hortonworks.com

  kerberos method = secrets and keytab

  idmap config * : backend = rid
  idmap config * : range = 10000-20000

  winbind use default domain = Yes
  winbind enum users = Yes
  winbind enum groups = Yes
  winbind nested groups = Yes
  winbind separator = +
  winbind refresh tickets = yes

  template shell = /bin/bash
  template homedir = /home/%U

  preferred master = no
  dns proxy = no
  wins server = activedirectory.hortonworks.com
  wins proxy = no

  inherit acls = Yes
  map acl inherit = Yes
  acl group control = yes

  load printers = no
  debug level = 3
  use sendfile = no
EOF

## 
sudo yum -y install sssd

sudo tee /etc/sssd/sssd.conf > /dev/null <<-'EOF'
[sssd]
config_file_version = 2
domains = hortonworks.com
services = nss, pam
debug_level = 0

[nss]

[pam]

[domain/hortonworks.com]

ldap_uri = ldap://activedirectory.hortonworks.com
ldap_default_bind_dn = CN=ldap-connect,cn=Users,dc=hortonworks,dc=com
ldap_default_authtok_type = password
ldap_default_authtok = "BadPass#1"
ldap_group_search_base = dc=hortonworks,dc=com
ldap_user_search_base = dc=hortonworks,dc=com

access_provider = ldap
id_provider = ldap
cache_credentials = True

ldap_id_use_start_tls = True
ldap_tls_cacertdir = /etc/pki/tls/certs
#ldap_tls_cacert = /etc/pki/ca-trust/source/anchors/activedirectory.pem
ldap_tls_cacert = /etc/pki/tls/certs/ca-bundle.crt
ldap_referrals = false
ldap_schema = rfc2307bis
ldap_access_order = expire
ldap_account_expire_policy = ad

ldap_group_object_class = group

ldap_user_object_class = user
ldap_user_home_directory = unixHomeDirectory
ldap_user_principal = userPrincipalName
ldap_user_shell = loginShell
EOF

sudo chmod 0600 /etc/sssd/sssd.conf
sudo chkconfig sssd on
sudo service sssd restart

sudo authconfig \
  --enablesssd \
  --enablesssdauth \
  --enablelocauthorize \
  --enableldap \
  --enableldapauth \
  --ldapserver=ldaps://activedirectory.hortonworks.com \
  --disableldaptls \
  --ldapbasedn=dc=hortonworks,dc=com \
  --enablerfc2307bis \
  --enablemkhomedir \
  --enablecachecreds \
  --update


