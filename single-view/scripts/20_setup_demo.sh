#!/usr/bin/env bash

cd ~

wget https://jdbc.postgresql.org/download/postgresql-9.4.1207.jar -P /usr/hdp/current/sqoop-client/lib

UID_MIN=$(awk '$1=="UID_MIN" {print $2}' /etc/login.defs)
users="${users:-$(getent passwd|awk -v UID_MIN="${UID_MIN}" -F: '$3>=UID_MIN{print $1}')}"
dfs_cmd="sudo sudo -u hdfs hadoop fs"
for user in ${users}; do
    usermod -a -G users "${user}"
    if ! ${dfs_cmd} -stat /user/${user} 2> /dev/null; then
      ${dfs_cmd} -mkdir -p "/user/${user}"
      ${dfs_cmd} -chown "${user}" "/user/${user}" &
    fi
done

(
cd /tmp
wget http://hortonworks-masterclass.s3.amazonaws.com/single-view/data.zip
unzip data.zip
)

echo "host all all 127.0.0.1/32 md5" >> /var/lib/pgsql/data/pg_hba.conf
service postgresql reload

git clone https://github.com/abajwa-hw/single-view-demo
sudo -i -u postgres psql -c "create database contoso;"
sudo -i -u postgres psql -c "CREATE USER zeppelin WITH PASSWORD 'zeppelin';"
sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE contoso to zeppelin;"
sudo -i -u postgres psql -c "\du"
export PGPASSWORD=zeppelin
psql -U zeppelin -d contoso -h localhost -f ~/single-view-demo/contoso-psql.sql
psql -U zeppelin -d contoso -h localhost -c "\dt"

echo "zeppelin  ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

wait

