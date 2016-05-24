#!/bin/bash
set -ex

static_old='10.65.170.11-10.65.170.70'
static_new='10.146.63.131-10.146.63.180'

reserverd_fir_old='10.65.170.1-10.65.170.10'
reserverd_fir_new='10.146.56.1-10.146.63.130'

reserverd_sec_old='10.65.170.253-10.65.170.254'
reserverd_sec_new='10.146.63.231-10.146.63.239'

networkid_old='0df6b258-f911-4fdf-8ff4-be14e523b97d'
networkid_new='c7056af1-72d5-4fc6-970c-a111d7f13942'

consul_server_ip_old='10.65.170.11'
consul_server_ip_new='10.146.63.131'

nats_ip_old='10.65.170.21'
nats_ip_new='10.146.63.141'

etcd_ip_old='10.65.170.14'
etcd_ip_new='10.146.63.134'

diego_database_ip_old='10.65.170.24'
diego_database_ip_new='10.146.63.144'

nfs_server_ip_old='10.65.170.27'
nfs_server_ip_new='10.146.63.147'

router_ip_old='10.65.170.31'
router_ip_new='10.146.63.151'

mysql_proxy_ip_old='10.65.170.37'
mysql_proxy_ip_new='10.146.63.157'

mysql_ip_old='10.65.170.40'
mysql_ip_new='10.146.63.160'

ccdb_ip_old='10.65.170.51'
ccdb_ip_new='10.146.63.171'

uaadb_ip_old='10.65.170.54'
uaadb_ip_new='10.146.63.174'

consoledb_ip_old='10.65.170.57'
consoledb_ip_new='10.146.63.177'

ha_proxy_ip_old='10.65.170.20'
ha_proxy_ip_new='10.146.63.140'

diego_brain_ip_old='10.65.170.19'
diego_brain_ip_new='10.146.63.139'

doppler_ip_old='10.65.170.58'
doppler_ip_new='10.146.63.178'

loggregator_trafficcontroller_ip_old='10.65.170.59'
loggregator_trafficcontroller_ip_new='10.146.63.179'

syslog_old='10.65.170.3'
syslog_new='10.146.63.130'

subnet_old='10.65.170.0/24'
subnet_new='10.146.56.0/21'

gateway_old='10.65.170.1'
gateway_new='10.146.63.253'

dns_old='10.65.162.2'
dns_new='10.146.63.249'

domain_old='pez.pivotal.io'
domain_new='pcf.vmware.com'

sed -e "s|$static_old|$static_new|" \
-e "s|$reserverd_fir_old|$reserverd_fir_new|" \
-e "s|$reserverd_sec_old|$reserverd_sec_new|" \
-e "s|$networkid_old|$networkid_new|" \
-e "s|$consul_server_ip_old|$consul_server_ip_new|" \
-e "s|$nats_ip_old|$nats_ip_new|" \
-e "s|$etcd_ip_old|$etcd_ip_new|" \
-e "s|$diego_database_ip_old|$diego_database_ip_new|" \
-e "s|$nfs_server_ip_old|$nfs_server_ip_new|" \
-e "s|$router_ip_old|$router_ip_new|" \
-e "s|$mysql_proxy_ip_old|$mysql_proxy_ip_new|" \
-e "s|$mysql_ip_old|$mysql_ip_new|" \
-e "s|$ccdb_ip_old|$ccdb_ip_new|" \
-e "s|$uaadb_ip_old|$uaadb_ip_new|" \
-e "s|$consoledb_ip_old|$consoledb_ip_new|" \
-e "s|$ha_proxy_ip_old|$ha_proxy_ip_new|" \
-e "s|$diego_brain_ip_old|$diego_brain_ip_new|" \
-e "s|$doppler_ip_old|$doppler_ip_new|" \
-e "s|$loggregator_trafficcontroller_ip_old|$loggregator_trafficcontroller_ip_new|" \
-e "s|$syslog_old|$syslog_new|" \
-e "s|$subnet_old|$subnet_new|" \
-e "s|$gateway_old|$gateway_new|" \
-e "s|$dns_old|$dns_new|" \
-e "s|$domain_old|$domain_new|" \
cf-pezlab.yml > cf-vmwarelab.yml
