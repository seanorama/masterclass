echo -e "\n==> Copy sample_twitter_data to HDFS\n"

sudo -u hdfs hdfs dfs -mkdir /masterclass/lab4
sudo -u hdfs hdfs dfs -mkdir /masterclass/lab4/twitter
sudo -u hdfs hdfs dfs -chmod 777  /masterclass/lab4/twitter
sudo -u hdfs hdfs dfs -put ./sample_twitter_data.txt /masterclass/lab4/twitter/
sudo -u hdfs hdfs dfs -chmod 666 /masterclass/lab4/twitter/sample_twitter_data.txt

echo -e "\n==> Copy JSON serde to /var/lib/hive\n"

sudo cp ./json-serde-1.1.9.9-Hive13-jar-with-dependencies.jar /var/lib/hive/
sudo chmod 777 /var/lib/hive/json-serde-1.1.9.9-Hive13-jar-with-dependencies.jar
