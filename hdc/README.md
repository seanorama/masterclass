export lab_prefix="crashcourse"            ## template for naming the cloudformation stacks
export lab_first=10                        ## number to start at in naming
export lab_count=3                         ## number of clusters to create
export cluster_type=hdp26-data-science-spark2
export ambari_pass=BadPass#1

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
clusters=$(hdc list-clusters)
for cluster in ${clusters}; do
  hdc terminate-cluster --cluster-name ${cluster}
done

