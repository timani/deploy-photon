#!/bin/bash
set -e

photon target set http://${ova_ip}:9000

#Destory Existing Deployments
if (( $(photon -n deployment list | head -1) > 0 )); then
    photon system destroy
fi

#Deploy Photon Controller
photon system deploy deploy-photon/manifests/photon/$photon_manifest 2>&1
echo "sleep 3 minutes while photon ctrlrs are starting"
sleep 180

#Target Photon Controller
PHOTON_CTRL_ID=$(photon deployment list | head -3 | tail -1)
PHOTON_CTRL_IP=$(photon deployment show $PHOTON_CTRL_ID | grep -E "LoadBalancer.*28080" | awk -F " " '{print$2}')

photon target set http://${PHOTON_CTRL_IP}:9000

##Create Tenant
photon -n tenant create $photon_tenant
photon -n tenant set $photon_tenant

##Create Project & Link Resources
photon -n resource-ticket create --name $photon_project-ticket --limits "vm.memory 3600 GB, vm 10000 COUNT" -t $photon_tenant
echo 'y' | photon project create --name $photon_project --limits "vm.memory 3600 GB, vm 10000 COUNT" -r $photon_project-ticket
photon -n project set $photon_project


#Show Project ID
photon project list
