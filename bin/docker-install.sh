#!/usr/bin/env bash

sudo mkdir -p /etc/sysctl.d
sudo tee /etc/sysctl.d/99-hadoop-ipv6.conf > /dev/null <<-'EOF'
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
sudo sysctl -e -p /etc/sysctl.d/99-hadoop-ipv6.conf

sudo yum update -y
sudo yum install -y docker git python-argparse
sudo service docker start
sudo groupadd docker
sudo gpasswd -a ${USER} docker
sudo su - ${USER}
#docker run hello-world

docker login --username=seanorama --email=seanorama@gmail.com

## build docker-ambari 2.2.0
git clone https://github.com/seanorama/docker-ambari
cd docker-ambari; git checkout 2.2.0
docker build -t sequenceiq/ambari ambari-server ; cd

## extend docker-ambari for training
git clone https://github.com/seanorama/masterclass
docker build -t seanorama/training masterclass/security-official
export IMAGE="seanorama/training"
export EXPOSE_DNS=true
export DOCKER_OPTS="--privileged=true"
#export DOCKER_OPTS="-p 8080:8080"
curl -Lo .amb j.mp/docker-ambari && . .amb && amb-start-cluster
docker exec -it amb-server sh -c 'chkconfig ambari-agent on; service ambari-agent start'
get-ambari-server-ip
sudo iptables -t nat -A  DOCKER -p tcp --dport 8080 -j DNAT --to-destination $AMBARI_SERVER_IP:8080

sudo sed -i -e "s/nameserver .*/nameserver $(get-consul-ip)/" /etc/resolv.conf
echo "search service.consul" | sudo tee -a /etc/resolv.conf

## deploy hdp
get-ambari-server-ip
export ambari_server=${AMBARI_SERVER_IP}
export ambari_services="HDFS MAPREDUCE2 PIG YARN ZOOKEEPER"
export host_count=skip
git clone https://github.com/seanorama/ambari-bootstrap
cd ambari-bootstrap/deploy
./deploy-recommended-cluster.bash
cd

docker run -d \
    -h kerberos.service.consul --name kerberos \
    -e BOOTSTRAP=1 \
    -e BRIDGE_IP=$(get-consul-ip) \
    -e NAMESERVER_IP=$(get-consul-ip) \
    -e REALM=SERVICE.CONSUL \
    -e DOMAIN_REALM=service.consul \
    -e SEARCH_DOMAINS="service.consul search.consul node.dc1.consul" \
    -v /etc/krb5.conf:/etc/krb5.conf \
    -v /dev/urandom:/dev/random sequenceiq/kerberos

KERBEROS_IP=$(docker inspect --format="{{.NetworkSettings.IPAddress}}" kerberos)
_consul-register-service kerberos ${KERBEROS_IP}

########################################
## guacamole
docker run --rm glyptodon/guacamole /opt/guacamole/bin/initdb.sh --postgres > initdb.sql
cat << EOF >> initdb.sql
CREATE USER guacamole_user WITH PASSWORD 'some_password';
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public TO guacamole_user;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA public TO guacamole_user;
EOF

PGPASSWORD=mysecretpassword
docker run --name postgres -h postgres.service.consul --dns $(get-consul-ip) -e POSTGRES_PASSWORD=${PGPASSWORD} -d postgres
_consul-register-service postgres \
    $(docker inspect --format="{{.NetworkSettings.IPAddress}}" postgres)

docker cp initdb.sql postgres:/tmp/initdb.sql
docker exec -it postgres sh -c 'createdb -U postgres guacamole_db'
docker exec -it postgres \
    sh -c 'exec psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -d guacamole_db -U postgres -f /tmp/initdb.sql'

docker run --name guacd -h guacd.service.consul --dns $(get-consul-ip) -d -p 4822:4822 glyptodon/guacd
docker run --name guacamole -h guacamole.service.consul --dns $(get-consul-ip) --link guacd:guacd \
    --link postgres:postgres      \
    -e POSTGRES_DATABASE=guacamole_db  \
    -e POSTGRES_USER=guacamole_user    \
    -e POSTGRES_PASSWORD=some_password \
    -d -p 80:8080 glyptodon/guacamole
docker run --name desktop -h desktop.service.consul --dns $(get-consul-ip) -d -p 5901:5901 -p 6901:6901 consol/centos-xfce-vnc

_consul-register-service postgres \
    $(docker inspect --format="{{.NetworkSettings.IPAddress}}" postgres)
_consul-register-service guacd \
    $(docker inspect --format="{{.NetworkSettings.IPAddress}}" guacd)
_consul-register-service guacamole \
    $(docker inspect --format="{{.NetworkSettings.IPAddress}}" guacamole)
_consul-register-service desktop \
    $(docker inspect --format="{{.NetworkSettings.IPAddress}}" desktop)

##

