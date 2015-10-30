#!/usr/bin/env bash
##############################################################################
# Note the loops and pause reduce overloading the AWS region during
# provisioning. Number of instances spawned per batch is controlled by the
# variable "batchcount", first sleep is in between each instance spawn, second
# sleep is between each batch of instances.
##############################################################################

####
export lab_prefix=${lab_prefix:-mc-sql}
lab_first=${lab_first:-1}
lab_count=${lab_count:-1}

clusters=$(seq -w ${lab_first} $((lab_first+lab_count-1)))
clusters=$(for cluster in ${clusters}; do echo ${lab_prefix}${cluster}; done)

echo "########################################################"
echo "## Clusters to be created:"
echo
echo ${clusters}
echo
echo "########################################################"

# quick check to ensure pre-reqs are setup
while true; do
    read -p "Proceed with creating these ${lab_count} clusters? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

# Don't change this, change the batchcount variable towards the end of script
batchcount=0

# change the list of fruit to vary the number of clusters deployed
for cluster in ${clusters}
do
  ((batchcount++))
  aws cloudformation create-stack --stack-name ${cluster} \
    --capabilities CAPABILITY_IAM \
    --template-body file://./cloudformation.json \
    --parameters ParameterKey=KeyName,ParameterValue=secloud \
        ParameterKey=OpenLocation,ParameterValue=0.0.0.0/0

  echo Initiated creation of $cluster cluster
# this is the sleep interval between instances
  sleep 5
########################################################
# change the value below to increase/decrease batch size
########################################################
  if [ $batchcount -eq 20 ]
  then
# this is the sleep interval between batches of instances
    sleep 600 
# Don't change this, change the batchcount variable above
    batchcount=0
  fi
done
