echo -e "\n==> Copy customer data to HDFS\n"

sudo -u hdfs hdfs dfs -mkdir /masterclass/
sudo -u hdfs hdfs dfs -mkdir /masterclass/lab2/
sudo -u hdfs hdfs dfs -mkdir /masterclass/lab2/customers
sudo -u hdfs hdfs dfs -chmod 777  /masterclass/lab2/customers
cp ./customers.txt /tmp
sudo -u hdfs hdfs dfs -put /tmp/customers.txt /masterclass/lab2/customers/data1.txt
sudo -u hdfs hdfs dfs -chmod 666 /masterclass/lab2/customers/data1.txt


echo -e "\n==> Create customer schema in Hive\n"

cat <<EOF > /tmp/customers.sql
CREATE EXTERNAL TABLE customers(
  first_name STRING,
  last_name STRING,
  address ARRAY<STRING>,
  email STRING,
  phone STRING
)
LOCATION "/masterclass/lab2/customers";
EOF

sudo -u hdfs hive -f /tmp/customers.sql
