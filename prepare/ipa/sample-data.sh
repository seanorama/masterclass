#!/usr/bin/env bash

## Authenticate to Kerberos
##  - Can override by exporting 'kinitpass=something' before executing
kinitpass=${kinitpass:-hortonworks}
echo ${kinitpass} | kinit admin
echo ${kinitpass} | sudo kinit admin

## Configurations
ipa config-mod --defaultshell=/bin/bash

########
## Create users, groups & set passwords
##

groups="marketing legal hr sales finance users"
users="gooduser baduser superuser ali paul sean legal1 legal2 legal3 hr1 hr2 hr3"
userpass=${userpass:-hortonworks}

## Add groups
for g in ${groups}; do
  ipa group-add ${g} --desc ${g}
done

## Add users and set passwords
for u in ${users}; do
  ipa user-add ${u} --first=${u} --last=User --shell=/bin/bash
  printf "${userpass}\n${userpass}" | ipa passwd ${u}
  ipa group-add-member users --users=${u}
done

ipa group-add-member sales --users=ali
ipa group-add-member sales --users=paul
ipa group-add-member finance --users=ali
ipa group-add-member finance --users=paul
ipa group-add-member legal --users=legal1
ipa group-add-member legal --users=legal2
ipa group-add-member legal --users=legal3
ipa group-add-member hr --users=hr1
ipa group-add-member hr --users=hr2
ipa group-add-member hr --users=hr3
ipa group-add-member admins --users=superuser
ipa group-add-member users --users=admin
