# Environment notes

## Note to Hortonworkers

Find our Active Directory instance details in Google Drive. Title "infrastructure" in the Training folder.

#### Configure name resolution & certificate to Active Directory

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
ldapsearch -W -D administrator@lab.hortonworks.net
   ```
