echo -e "\n==> Copy sample_twitter_data to HDFS\n"

mkdir -p /tmp/Lab4
cp -a * /tmp/Lab4/

sudo -u hdfs hdfs dfs -mkdir -p /masterclass/lab4
sudo -u hdfs hdfs dfs -mkdir /masterclass/lab4/twitter
sudo -u hdfs hdfs dfs -chmod 777  /masterclass/lab4/twitter
sudo -u hdfs hdfs dfs -put /tmp/Lab4/sample_twitter_data.txt /masterclass/lab4/twitter/
sudo -u hdfs hdfs dfs -chmod 666 /masterclass/lab4/twitter/sample_twitter_data.txt


echo -e "\n==> Copy JSON serde to /var/lib/hive\n"

sudo -u hdfs hdfs dfs -mkdir -p /lib/hive
sudo -u hdfs hdfs dfs -put /tmp/Lab4/json-serde-1.1.9.9-Hive13-jar-with-dependencies.jar /lib/hive/
sudo cp /tmp/Lab4/json-serde-1.1.9.9-Hive13-jar-with-dependencies.jar /var/lib/hive/
sudo chmod 644 /var/lib/hive/json-serde-1.1.9.9-Hive13-jar-with-dependencies.jar

if [ ! -d ~/ambari-bootstrap ]; then
    cd
    git clone https://github.com/seanorama/ambari-bootstrap
fi

source ~/ambari-bootstrap/extras/ambari_functions.sh
ambari_configs

${ambari_config_get} hive-env \
    | sed -e '1,3d' \
    -e '/^"content" : / s#",$#\\n\\nHIVE_AUX_JARS_PATH=$HIVE_AUX_JARS_PATH:/var/lib/hive/json-serde-1.1.9.9-Hive13-jar-with-dependencies.jar",#' \
    > /tmp/hive-env.json
${ambari_config_set} hive-env /tmp/hive-env.json

