# Instructor notes
========================================

## Before you start

See ../README.md for instructions on using the cluster management scripts.

### a) Deploy cluster(s)

1. Get the repo and switch to the 'generic' directory

    ```
git clone https://github.com/seanorama/masterclass
cd masterclass/generic
    ```

2. Set these variables, updating the values as appropriate:

   ```sh
export AWS_DEFAULT_REGION=eu-central-1  ## region to deploy in
export lab_prefix="${USER}"          ## template for naming the cloudformation stacks
export lab_first=100                 ## number to start at in naming
export lab_count=1                   ## number of clusters to create

export cfn_parameters='
[
  {"ParameterKey":"KeyName","ParameterValue":"secloud"},
  {"ParameterKey":"SubnetId","ParameterValue":"subnet-025cae79"},
  {"ParameterKey":"SecurityGroups","ParameterValue":"sg-d6c31dbd"},
  {"ParameterKey":"AdditionalInstanceCount","ParameterValue":"0"},
  {"ParameterKey":"AmbariServices","ParameterValue":"HDFS MAPREDUCE2 PIG YARN HIVE ZOOKEEPER AMBARI_INFRA AMBARI_METRICS SQOOP TEZ ZEPPELIN SLIDER SPARK RANGER ATLAS KAFKA"},
  {"ParameterKey":"AdditionalInstanceCount","ParameterValue":"0"},
  {"ParameterKey":"DeployCluster","ParameterValue":"true"},
  {"ParameterKey":"AmbariVersion","ParameterValue":"2.5.0.3"},
  {"ParameterKey":"HDPStack","ParameterValue":"2.6"},
  {"ParameterKey":"PostCommand","ParameterValue":"curl -sSL https://raw.githubusercontent.com/seanorama/masterclass/master/ranger-atlas/setup.sh | bash"},
  {"ParameterKey":"InstanceType","ParameterValue":"m4.2xlarge"},
  {"ParameterKey":"BootDiskSize","ParameterValue":"80"}
]
'
   ```

3. Create the cluster(s): `../bin/clusters-create.sh`

4. List cluster host(s): `../bin/clusters-report.sh`

5. Terminate cluster(s): `../bin/clusters-terminate.sh`

## REMEMBER to terminate the clusters immediately after the class is over, or be prepared to pay $$$!

Further, you should verify deletion of the CloudFormations & EC2 instances from the AWS Console.

## Extra commands needed

These additional steps are needed once the clusters are deployed. Use a cluster shell to execute.

```
## this will give you a command to open tmux-cssh to all hosts:
echo ${hosts} | xargs echo tmux-cssh -sa \"-o StrictHostKeyChecking=no\" -u centos blah
```

```
ad_host="ad01.lab.hortonworks.net"
ad_root="ou=CorpUsers,dc=lab,dc=hortonworks,dc=net"
ad_user="cn=ldap-reader,ou=ServiceUsers,dc=lab,dc=hortonworks,dc=net"

sudo ambari-server setup-ldap \
  --ldap-url=${ad_host}:389 \
  --ldap-secondary-url= \
  --ldap-ssl=false \
  --ldap-base-dn=${ad_root} \
  --ldap-manager-dn=${ad_user} \
  --ldap-bind-anonym=false \
  --ldap-dn=distinguishedName \
  --ldap-member-attr=member \
  --ldap-group-attr=cn \
  --ldap-group-class=group \
  --ldap-user-class=user \
  --ldap-user-attr=sAMAccountName \
  --ldap-save-settings \
  --ldap-bind-anonym=false \
  --ldap-sync-username-collisions-behavior=convert \
  --ldap-referral=

sudo ambari-server restart
echo hadoop-users,hr,sales,legal,hadoop-admins,compliance,analyst,eu_employees,us_employees > groups.txt
sudo ambari-server sync-ldap --groups groups.txt


## set role permissions in ambari
ambari_pass=BadPass#1
source ~/ambari-bootstrap/extras/ambari_functions.sh
ambari_get_cluster
: ${cluster_name:=${ambari_cluster}}
read -r -d '' body <<EOF
[{"PrivilegeInfo":{"permission_name":"CLUSTER.USER","principal_name":"hadoop-users","principal_type":"GROUP"}}]'
EOF
echo "${body}" | ${ambari_curl}/clusters/${cluster_name}/privileges \
  -v -X PUT -d @-
read -r -d '' body <<EOF
[{"PrivilegeInfo":{"permission_name":"CLUSTER.USER","principal_name":"hadoop-users","principal_type":"GROUP"}},{"PrivilegeInfo":{"permission_name":"CLUSTER.ADMINISTRATOR","principal_name":"hadoop-admins","principal_type":"GROUP"}}]
EOF
echo "${body}" | ${ambari_curl}/clusters/${cluster_name}/privileges \
  -v -X PUT -d @-



API call to add groups to roles
- see screenshot on desktop


```


## Issues: See ../README.md

## Advanced usage

1. Only deploy the infrastructure by setting PostCommand to /bin/true
