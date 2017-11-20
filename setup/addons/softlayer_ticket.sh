#!/bin/bash
#
# vim:set ts=2 sw=2:

cat <<EOF |sudo tee /etc/logstash/conf.d/51-softlayer-ticket.conf
input {
	udp {
		type => softlayer_ticket
		port => "$port_softlayer_ticket"
		codec => json_lines
		add_field => { "received_at" => "%{@timestamp}" }
		add_field => { "[@metadata][output]" => "self" }
	}
}

filter {
	if [type] == "softlayer_ticket" {
		date {
			match => [ "createDate", "ISO8601" ]
		}
		mutate {
			add_field => { "proxy" => "%{host}" }
		}
	}
}

output {
	if [type] == "softlayer_ticket" {
		elasticsearch {
			hosts => ["127.0.0.1"]
			index => "softlayer_ticket-%{+YYYY.MM}"
		}
	}
}
EOF

# upload mapping template
#curl -XPUT localhost:9200/_template/softlayer_ticket \
#		-d @$assets_dir/template-softlayer_ticket.json

# setup firewall
cat <<EOF |sudo tee /etc/ufw/applications.d/silrok-softlayer-ticket
[Silrok-Logstash-Ticket]
title=Silrok-Logstash-Ticket
description=Silrok Logstash Ticket
ports=$port_softlayer_ticket/udp
EOF

sudo ufw allow from any to any app Silrok-Logstash-Ticket

