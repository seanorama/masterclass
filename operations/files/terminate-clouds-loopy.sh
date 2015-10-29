#!/bin/bash
##############################################################################
# Note the loops and pause reduce overloading the AWS region during
# deletion. Number of instances deleted per batch is controlled by the
# variable "batchcount", first sleep is in between each instance deletion, second
# sleep is between each batch of instances.
##############################################################################

# full set of 35 fruits, use as many as necessary
# apple apricot banana blackberry blackcurrant blueberry coconut cherry clementine cranberry damson elderberry fig gooseberry grape guava huckleberry lemon lime lychee mango melon nectarine orange passionfruit peach pear plum prune pineapple pomegranate raspberry satsuma strawberry tangerine

#export clusters="apple apricot banana blackberry blackcurrant blueberry coconut cherry clementine cranberry damson elderberry fig gooseberry grape guava huckleberry lemon lime lychee mango melon nectarine orange passionfruit peach pear persimmon plum prune pineapple pomegranate raspberry satsuma strawberry tangerine"
clusters=${clusters:-apple}
echo ${clusters}


# quick safety check to ensure termination is required
while true; do
    read -p "Do you wish terminate all masterclass instances? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

# Don't change this, change the batchcount test lower down the end of script
batchcount=0

# change the list of fruit to vary the number of clusters deleted
for fruitycluster in ${clusters}
do 
  ((batchcount++))
  aws cloudformation delete-stack --stack-name $fruitycluster
  echo Initiated deletion of $fruitycluster cluster
# this is the sleep interval between instances
  sleep 5 
########################################################
# change the value below to increase/decrease batch size
########################################################
  if [ $batchcount -eq 7 ]
  then
# this is the sleep interval between batches of instances
    sleep 20
# Don't change this, change the batchcount variable above
    batchcount=0
  fi
done
