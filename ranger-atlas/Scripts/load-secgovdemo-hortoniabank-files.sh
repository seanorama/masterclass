#!/usr/bin/env bash

#sudo su -
#kinit -kt /etc/security/keytabs/hdfs.headless.keytab hdfs-hortoniabank@FIELD.HORTONWORKS.COM

cp -a ../Data /tmp
bunzip2 /tmp/Data/*.bz2


sudo sudo -u hdfs bash -c "
  hdfs dfs -mkdir -p /user/admin/hortoniabank_data/us_customers
  hdfs dfs -mkdir -p /user/admin/hortoniabank_data/ww_customers
  hdfs dfs -mkdir -p /user/admin/hortoniabank_data/eu_countries
  hdfs dfs -mkdir -p /user/admin/hortoniabank_data/tax_2015
  hdfs dfs -mkdir -p /user/admin/hortoniabank_data/claim_savings
  hdfs dfs -mkdir -p /user/admin/hortoniabank_data/provider_summary

  hdfs dfs -put /tmp/Data/us_customers_data.csv /user/admin/hortoniabank_data/us_customers
  hdfs dfs -put /tmp/Data/ww_customers_data.csv /user/admin/hortoniabank_data/ww_customers
  hdfs dfs -put /tmp/Data/eu_countries.csv /user/admin/hortoniabank_data/eu_countries
  hdfs dfs -put /tmp/Data/tax_2015.csv /user/admin/hortoniabank_data/tax_2015
  hdfs dfs -put /tmp/Data/claim_savings.csv /user/admin/hortoniabank_data/claim_savings
  hdfs dfs -put /tmp/Data/claims_provider_summary_data.csv /user/admin/hortoniabank_data/provider_summary
  hdfs dfs -chown -R admin:hadoop /user/admin/hortoniabank_data
  hdfs dfs -chmod -R g+wX /user/admin/hortoniabank_data
"



