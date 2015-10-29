# Create employees database

# echo -e "\n==> Install git\n"

# sudo yum install -y git

echo -e "\n==> Clone sample database\n"

cd /tmp

git clone https://github.com/datacharmer/test_db

echo -e "\n==> Create sample database\n"

cd test_db
mysql -u root < employees.sql

# Convert to tsv

echo -e "\n==> Convert employees table to tsv\n"

mkdir /tmp/employees_tsv
chmod 777 /tmp/employees_tsv/
sudo mysqldump --tab /tmp/employees_tsv/ employees

# Import into HDFS

echo -e "\n==> Import employees table into HDFS as tsv\n"

sudo -u hdfs hdfs dfs -mkdir /tmp/employees_tsv
sudo -u hdfs hdfs dfs -put /tmp/employees_tsv/*.txt /tmp/employees_tsv
sudo -u hdfs hdfs dfs -chmod 666 /tmp/employees_tsv/*.txt

# Create HBase database

echo -e "\n==> Create HBase database employees\n"

cat <<EOF > /tmp/hbase.txt
create "employees", {NAME => "f"}, {SPLITS => ["200000", "300000", "400000"]}
enable "employees"
exit
EOF

hbase shell /tmp/hbase.txt


# Import data from tsv file

echo -e "\n==> Import tsv from HDFS into employees\n"

sudo -u hdfs hbase org.apache.hadoop.hbase.mapreduce.ImportTsv \
                   -Dimporttsv.columns=HBASE_ROW_KEY,f:birth_date,f:first_name,f:last_name,f:gender,f:hire_date \
                   employees /tmp/employees_tsv/employees.txt

