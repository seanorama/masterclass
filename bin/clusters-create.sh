#!/usr/bin/env bash
#
## Create Cloudformations in batches

## Note:
##   Your default AWS region will be used. Override by executing this before the scripts:
##   export AWS_DEFAULT_REGION=eu-west-1
##

####
lab_ssh_key=${lab_key:-secloud}
lab_location="${lab_location:-0.0.0.0/0}"
lab_prefix=${lab_prefix:-mc-test}
lab_first=${lab_first:-1}
lab_count=${lab_count:-1}
lab_batch=${lab_batch:-20} ## how many cluster to deploy at a time
lab_batch_delay=${lab_batch_delay:-300} ## seconds to wait between batches
cfn_parameters=${cfn_parameters:-}
cfn_switches=${cfn_switches:-}

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

batchcounter=0
for cluster in ${clusters}
do
  ((batchcounter++))
  aws cloudformation create-stack --stack-name ${cluster} \
    --capabilities CAPABILITY_IAM \
    --template-body file://./cloudformation.json \
    --parameters ParameterKey=KeyName,ParameterValue=${lab_ssh_key} \
        ${cfn_parameters} \
        ${cfn_switches}
        #ParameterKey=OpenLocation,ParameterValue=${lab_location} \

########################################################################
  echo Initiated creation of $cluster cluster

  sleep 5
  if [ $batchcounter -eq ${lab_batch} ]; then
    sleep ${lab_batch_delay}
    batchcounter=0
  fi
done
