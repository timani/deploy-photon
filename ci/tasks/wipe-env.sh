#!/bin/bash +x

if [ $wipe_arg == "wipe" ];
        then
                echo "Wiping Environment...."
        else
                echo "Need Args [0]=wipe "
                echo "Example: ./p1-0-wipe-env.sh wipe ..."
                exit 1
fi

ESX_USER=$esx_user
ESX_PASSWD=$esx_passwd

IFS=',' read -r -a ESX_HOSTS <<< "$esx_hosts"


#Grab Host IP Addresses & PowerOff/Unregister VMS
        for x in "${ESX_HOSTS[@]}"; do
                echo "Removing VMs From host=$x ..."
                for VM in $(vmware-cmd -U $ESX_USER -P $ESX_PASSWD --server $x -l | grep -v "vRLI"); do
                        if [ $VM != "No virtual machine found." ]; then
                                vmware-cmd -U $ESX_USER -P $ESX_PASSWD --server $x $VM stop hard
                                vmware-cmd -U $ESX_USER -P $ESX_PASSWD --server $x -s unregister $VM
                        fi
                done
                HOST=$x
        done

#Clean DataStore(s)
        for d in $(cat $deployment_manifest | grep DATASTORE | awk -F ":" '{print $2}' |  tr "," "\n" | sort -u); do
                vifs --server $HOST --username $ESX_USER --password $ESX_PASSWD --rm  "[$d] disks" --force || echo "Already Wiped"
                vifs --server $HOST --username $ESX_USER --password $ESX_PASSWD --rm  "[$d] tmp_images" --force || echo "Already Wiped"
                vifs --server $HOST --username $ESX_USER --password $ESX_PASSWD --rm  "[$d] tmp_uploads" --force || echo "Already Wiped"
                vifs --server $HOST --username $ESX_USER --password $ESX_PASSWD --rm  "[$d] images" --force || echo "Already Wiped"
                vifs --server $HOST --username $ESX_USER --password $ESX_PASSWD --rm  "[$d] vms" --force || echo "Already Wiped"
                vifs --server $HOST --username $ESX_USER --password $ESX_PASSWD --rm  "[$d] vibs" --force || echo "Already Wiped"
                vifs --server $HOST --username $ESX_USER --password $ESX_PASSWD --rm  "[$d] deleted_images" --force || echo "Already Wiped"
        done
