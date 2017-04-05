# Hortonworks Data Cloud

## Fetch this repo
```
sudo yum -y install git
git clone https://github.com/seanorama/masterclass
cd masterclass/hdc
```

## Demo HDCloud

### Demo: Show deployment options and integrations
1. Create HDCloud Controller
2. From HDCloud:
  - Register Authentication (LDAP)
  - Register Hive MetaStore (Postgresql on AWS RDS)
3. From HDCloud:
  - Create Shared Data Lake Services
5. From HDCloud:
  - Create Clusters

### Demo: Show CLI

1. SSH to Cloud controller
2. Use `hdc` cli


```
## show options
hdc

## list clusters
hdc list-clusters -output table

## create a cluster
hdc create-cluster --cli-input-json ./templates/cluster-datascience.json --input-json-param-ClusterAndAmbariPassword ${pass}
```

--------

# Automated Deployment of many clusters

## Deploy clusters

Set below before executing other commands:
```
export lab_prefix="crashcourse"            ## template for naming the cloudformation stacks
export lab_first=10                        ## number to start at in naming
export lab_count=3                         ## number of clusters to create
export cluster_type=hdp26-data-science-spark2
export ambari_pass=BadPass#1
```

Commands to manage clusters:
```
## create clusters
../bin/hdc-clusters-create.sh

## list clusters and check status
hdc list-clusters -output table

## get name & master's IP for all available clusters
clusters=$(hdc list-clusters | jq -r '.[]|select(.Status=="AVAILABLE")|.ClusterName')
for cluster in ${clusters}; do
  printf "${cluster}\t$(hdc describe-cluster instances --cluster-name ${cluster} | jq -r '.[] | select(.Type =="master - ambari server")|.PublicIP')\n"
done

## terminate the above clusters
../bin/hdc-clusters-terminate.sh

## terminate ALL clusters managed by this HDCloud controller
## WARNING: THIS WILL TERMINATE ALL CLUSTERS WITHOUT PROMPTING YOU!!!!
clusters=$(hdc list-clusters | jq -r '.[].ClusterName')
for cluster in ${clusters}; do
  hdc terminate-cluster --cluster-name ${cluster}
done
```

