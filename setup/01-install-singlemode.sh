#!/bin/bash
#
set -xe

GPG_KEY=https://artifacts.elastic.co/GPG-KEY-elasticsearch

sudo apt-get install -y openjdk-8-jre-headless
wget -qO - $GPG_KEY | sudo apt-key add -

cat <<EOF | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list
deb https://artifacts.elastic.co/packages/6.x/apt stable main
EOF

sudo apt-get update
sudo apt-get install -y elasticsearch
sudo apt-get install -y logstash
sudo apt-get install -y kibana

sudo sed -i "s/.*cluster.name: .*/cluster.name: $cluster_name/" \
	/etc/elasticsearch/elasticsearch.yml
sudo sed -i 's/.*node.name: .*/node.name: ${HOSTNAME}/' \
	/etc/elasticsearch/elasticsearch.yml
sudo sed -i 's/.*server.host: .*/server.host: "0.0.0.0"/' \
	/etc/kibana/kibana.yml

cat <<EOF |sudo tee /etc/ufw/applications.d/silrok-kibana
[Silrok-Kibana]
title=Silrok-Kibana
description=Silrok Kibana
ports=$kibana_port/tcp
EOF
sudo ufw allow from $admin_network to any app Silrok-Kibana
sudo ufw reload

cat <<EOF |sudo tee /etc/logstash/conf.d/99-local-elastic.conf
input {
  file {
    type => "syslog-local"
    path => [ "/var/log/elasticsearch/*.log", "/var/log/logstash/*.log" ]
  }
}

output {
  if [@metadata][output] != "self" {
    elasticsearch {
      hosts => ["127.0.0.1"]
    }
  }
  if "_jsonparsefailure" in [tags] {
    stdout { codec => rubydebug { metadata => true } }
  }
  if "_grokparsefailure" in [tags] {
    stdout { codec => rubydebug { metadata => true } }
  }
  if "_debug" in [tags] {
    stdout { codec => rubydebug { metadata => true } }
  }
}
EOF

sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service 
sudo systemctl enable logstash.service
sudo systemctl enable kibana.service
sudo systemctl start elasticsearch.service 
sudo systemctl start logstash.service
sudo systemctl start kibana.service
