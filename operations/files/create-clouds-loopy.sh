#!/usr/bin/env bash
##############################################################################
# Note the loops and pause reduce overloading the AWS region during
# provisioning. Number of instances spawned per batch is controlled by the
# variable "batchcount", first sleep is in between each instance spawn, second
# sleep is between each batch of instances.
##############################################################################

####
#export clusters="apple apricot banana blackberry blackcurrant blueberry coconut cherry clementine cranberry elderberry fig gooseberry grape guava huckleberry lemon lime lychee mango melon nectarine orange passionfruit peach pear persimmon plum prune pineapple pomegranate raspberry satsuma strawberry tangerine"
clusters=${clusters:-apple}

# quick check to ensure pre-reqs are setup
while true; do
    read -p "Is the proxy hostname correctly setup in the cfn template and proxy is running? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

# Don't change this, change the batchcount variable towards the end of script
batchcount=0

# change the list of fruit to vary the number of clusters deployed
for fruitycluster in ${clusters}
do
  ((batchcount++))
  aws cloudformation create-stack --stack-name $fruitycluster --template-body file://./cfn-ambari-opsmasterclass.template-24.json --parameters ParameterKey=KeyName,ParameterValue=secloud --capabilities CAPABILITY_IAM
  echo Initiated creation of $fruitycluster cluster
# this is the sleep interval between instances
  sleep 5
########################################################
# change the value below to increase/decrease batch size
########################################################
  if [ $batchcount -eq 6 ]
  then
# this is the sleep interval between batches of instances
    sleep 600 
# Don't change this, change the batchcount variable above
    batchcount=0
  fi
done
