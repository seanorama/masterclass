echo -e "\n==> Copy tweets data to HDFS\n"

tar -C / -zxf ./tweets.tgz

sudo -u hdfs hdfs dfs -mkdir /masterclass/lab3
sudo -u hdfs hdfs dfs -mkdir /masterclass/lab3/tweets
sudo -u hdfs hdfs dfs -chmod 777  /masterclass/lab3/tweets
sudo -u hdfs hdfs dfs -put /tmp/tweets/* /masterclass/lab3/tweets/
sudo -u hdfs hdfs dfs -chmod 666 /masterclass/lab3/tweets/*

