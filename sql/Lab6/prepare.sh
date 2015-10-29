cat <<EOF > /tmp/db.sql
CREATE DATABASE employees;
EOF

echo -e "\n==> Creating database employees in hive\n"

beeline -u jdbc:hive2://localhost:10000/default -n student -f /tmp/db.sql


for table in departments dept_emp dept_manager employees salaries titles; do 
  
  echo -e "\n==> Importing table $table into hive\n"
  
  sudo -u hive sqoop import --connect jdbc:mysql://localhost/employees \
                            --username root --table $table \
                            --hive-import --hive-table employees.$table --direct --m 1; 
done
