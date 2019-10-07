#!/bin/bash

crm configure<<EOF
property no-quorum-policy=ignore
property stonith-enabled=no
primitive p-apache apache \
	params configfile="/etc/apache2/httpd.conf" statusurl="http://172.30.100.2/server-status" \
	op start timeout=40s interval=0 \
	op stop timeout=60s interval=0 \
	op monitor timeout=20s interval=10s
primitive p-IP_100_2 IPaddr2 \
	params ip=172.30.100.2 nic=eth1 cidr_netmask=24 \
	op start timeout=20s interval=0 \
	op stop timeout=20s interval=0 \
	op monitor timeout=20s interval=10s
group g-apache p-IP_100_2 p-apache \
	meta target-role=Started
EOF
