#!/usr/bin/env bash

export lab_prefix=${lab_prefix:-${USER}}
lab_first=${lab_first:-100}
lab_count=${lab_count:-1}

clusters=$(seq -w ${lab_first} $((lab_first+lab_count-1)))
clusters=$(for cluster in ${clusters}; do echo ${lab_prefix}${cluster}; done)

echo "########################################################"
echo "## Clusters to be terminated:"
echo
echo ${clusters}
echo
echo "########################################################"

# quick safety check to ensure termination is required
while true; do
    read -p "Do you wish terminate all of these clusters? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

# Don't change this, change the batchcount test lower down the end of script
batchcount=0

# change the list of fruit to vary the number of clusters deleted
for cluster in ${clusters}
do 
  ((batchcount++))
  aws cloudformation delete-stack --stack-name $cluster
  echo Initiated deletion of $cluster cluster
# this is the sleep interval between instances
  sleep 5 
########################################################
# change the value below to increase/decrease batch size
########################################################
  if [ $batchcount -eq 20 ]
  then
# this is the sleep interval between batches of instances
    sleep 20
# Don't change this, change the batchcount variable above
    batchcount=0
  fi
done
