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

groups="marketing legal hr sales finance"
users="gooduser baduser superuser ali paul legal1 legal2 legal3 hr1 hr2 hr3"
userpass=${userpass:-hortonworks}

## Add groups
for g in ${groups}; do
  ipa group-add ${g} --desc ${g}
done

## Add users and set passwords
for u in ${users}; do
  ipa user-add ${u} --first=${u} --last=User --shell=/bin/bash
  printf "${userpass}\n${userpass}" | ipa passwd ${u}
done

ipa group-add-member sales --users=ali,paul
ipa group-add-member finance --users=ali,paul
ipa group-add-member legal --users=legal1,legal2,legal3
ipa group-add-member hr --users=hr1,hr2,hr3
ipa group-add-member admins --users=superuser
