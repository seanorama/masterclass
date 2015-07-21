#!/usr/bin/env bash

## for active directory only since we won't be syncing users
ldap_user=ldap-connect@hortonworks.com
ldap_pass="BadPass#1"
users=$(ldapsearch -w ${ldap_pass} -D ${ldap_user} "(UnixHomeDirectory=/home/*)" sAMAccountName | awk '/^sAMAccountName: / {print $2}')
for user in ${users}; do
  if ! id -u ${user}; then
    sudo useradd -G users ${user}
    printf "BadPass#1\nBadPass#1" | sudo passwd ${user}
  fi
done


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


