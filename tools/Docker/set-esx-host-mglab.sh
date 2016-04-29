##############################################
#     ESXi 6.0 U2 Photon Cfg Script  mglab   #
##############################################



#########################################
IPADDR=$2
THUMBPRINT=$(esxcli -s ${2} | egrep -o "thumbprint: .* \(not trusted\)" | awk -F " " '{print$2}')
ISCSI1_ADDRESS=$3
#########################################



###########################
#  vSwitch configuration  #
###########################



## Add Port Groups
esxcli -s $2 -d $THUMBPRINT -u root -p $4 network vswitch standard portgroup add -p "pg-mglab-access-vlan-100-T" -v vSwitch0
esxcli -s $2 -d $THUMBPRINT -u root -p $4 network vswitch standard portgroup set -p "pg-mglab-access-vlan-100-T" -v 100
esxcli -s $2 -d $THUMBPRINT -u root -p $4 network vswitch standard portgroup add -p "pg-mglab-stg-vlan-20-T" -v vSwitch0
esxcli -s $2 -d $THUMBPRINT -u root -p $4 network vswitch standard portgroup set -p "pg-mglab-stg-vlan-20-T" -v 20


## Config vSwitch  for Jumbo / iSCSI
esxcli -s $2 -d $THUMBPRINT -u root -p $4 network vswitch standard set --mtu 9000 --cdp-status both --vswitch-name vSwitch0


## add network interfaces and assign IPs
esxcli -s $2 -d $THUMBPRINT -u root -p $4 network ip interface add --interface-name vmk1 --mtu 9000 --portgroup-name pg-mglab-stg-vlan-20-T
esxcli -s $2 -d $THUMBPRINT -u root -p $4 network ip interface ipv4 set --interface-name vmk1 --ipv4 ${ISCSI1_ADDRESS} --netmask 255.255.255.0 --type static


##########################
#  ISCSI Configuration   #
##########################
esxcli -s $2 -d $THUMBPRINT -u root -p $4 iscsi software set --enabled=true
ADAPTER=$(esxcli -s $2 -d $THUMBPRINT -u root -p $4 iscsi adapter list | grep iscsi_vmk | head -1 | awk -F " " '{print$1}')
esxcli -s $2 -d $THUMBPRINT -u root -p $4 iscsi networkportal add -A ${ADAPTER} -n vmk1
esxcli -s $2 -d $THUMBPRINT -u root -p $4 iscsi adapter set -A ${ADAPTER} --name iqn.1998-01.com.vmware:${1}
esxcli -s $2 -d $THUMBPRINT -u root -p $4 iscsi adapter discovery sendtarget add -A ${ADAPTER} -a 192.168.20.10
esxcli -s $2 -d $THUMBPRINT -u root -p $4 storage core adapter rescan --adapter ${ADAPTER}




# NTP Config
vicfg-ntp --server $2 --username root --password $4 --add 0.pool.ntp.org
vicfg-ntp --server $2 --username root --password $4 --add 1.pool.ntp.org
vicfg-ntp --server $2 --username root --password $4 --start

# enter maintenance mode
#esxcli system maintenanceMode set -e true

# Reboot host to finish all setup
#esxcli system shutdown reboot -d 60 -r "rebooting after host configurations"
