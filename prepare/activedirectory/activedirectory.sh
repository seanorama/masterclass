#!/usr/bin/env bash

sudo yum -y install openldap-clients bind-utils krb5-workstation ca-certificates

ad_host="activedirectory.$(hostname -d)"
ad_host_ip=$(ping -w 1 ${ad_host} | awk 'NR==1 {print $3}' | sed 's/[()]//g')
echo "${ad_host_ip} activedirectory.hortonworks.com ${ad_host} activedirectory" | sudo tee -a /etc/hosts

ad_cert=/etc/pki/ca-trust/source/anchors/activedirectory.pem
sudo tee ${ad_cert} > /dev/null <<-'EOF'
-----BEGIN CERTIFICATE-----
MIIDrTCCApWgAwIBAgIQFNSgEcmw1r9OP9AicCaGdDANBgkqhkiG9w0BAQUFADBd
MRMwEQYKCZImiZPyLGQBGRYDY29tMRswGQYKCZImiZPyLGQBGRYLaG9ydG9ud29y
a3MxKTAnBgNVBAMTIGhvcnRvbndvcmtzLUFDVElWRURJUkVDVE9SWS1DQS0xMB4X
DTE1MDcxNzIxMDI0N1oXDTIwMDcxNzIxMTI0N1owXTETMBEGCgmSJomT8ixkARkW
A2NvbTEbMBkGCgmSJomT8ixkARkWC2hvcnRvbndvcmtzMSkwJwYDVQQDEyBob3J0
b253b3Jrcy1BQ1RJVkVESVJFQ1RPUlktQ0EtMTCCASIwDQYJKoZIhvcNAQEBBQAD
ggEPADCCAQoCggEBAL6hKjn05Wr2/seMjrIYjdTG03sAeK1U5htzIJTZr7YWCJi0
fpj9NyIxYnQ58jxCnvq5dHVCExSzXCGvYhxoqk/VlA2puT1olrCPdakkBldj5S6l
0zUgauP4TQhBGVOnnBnfGOunfp2LP7yFj/QNCvQfKFeDeFptDiEEGyKO02Vif0Hp
IpS4Qqsk34kgPZ7Qy52frXIWLpndGQKsRFik3dNKcayP47ld4kRlrjvWJ0U5QZsj
Y1wIPf+VMCyp+npUraKO9wMguBbjwzU6PpsiLe1I/s11aq4lhCDaJoh9qOHXwBY5
YV9nl3bxJ79Xi1t23QG4+yUEgGGPkroCLHHWXN0CAwEAAaNpMGcwEwYJKwYBBAGC
NxQCBAYeBABDAEEwDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHQYD
VR0OBBYEFNG0iZwgi9cFiSMBVirEZ49fLYKiMBAGCSsGAQQBgjcVAQQDAgEAMA0G
CSqGSIb3DQEBBQUAA4IBAQBmb05AMnh7PFisKLsQnz3US/hMf1RM1WZl8DmS3sSx
rh5tYsg2UTp3mbm8VG6aFMYYzhazIt1u2JLN5r5DwTVHvG44r5hOQ37LImUr2W5W
ZnTeGdLU7uEV6RUSN5RtjIN7AHosIQik+dXt2BhdNyoYY9GsLvjfNO7IhBSGlmz9
ZP1AFD4f0oMDCETkSSvb1nW2sCjrMkA5ttxO/IKq8kaim/nPsXA4yO6Fbbrd/Y8C
e4XWhj04QLBbncIvRmyQMHD1DGLlLVeS2/LPMGR8ThYOk9Kh9MhZqx56eV7bPiU1
vxeIATwrsETUfRhyKA2oM1X0DJ1ZjxSDNIXJH6HNd4TA
-----END CERTIFICATE-----
EOF

sudo update-ca-trust enable
sudo update-ca-trust extract; sudo update-ca-trust check
sudo keytool -import -trustcacerts -noprompt -storepass changeit \
  -file ${ad_cert} -keystore /etc/pki/java/cacerts
sudo keytool -importcert -noprompt -storepass changeit \
  -file ${ad_cert} -keystore /etc/pki/java/cacerts
sudo keytool -import -trustcacerts -noprompt -storepass changeit \
  -file ${ad_cert} -keystore /var/lib/ambari-server/keys/ldaps-keystore.jks

sudo tee /etc/openldap/ldap.conf > /dev/null <<-EOF
SASL_NOCANON    on
URI ldaps://activedirectory.hortonworks.com
BASE dc=hortonworks,dc=com
TLS_CACERTDIR /etc/pki/tls/certs
TLS_CACERT /etc/pki/tls/certs/ca-bundle.crt
EOF
## can test with:
#ldapsearch -W -D user@domain.com

exit

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
