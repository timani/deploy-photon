#!/bin/bash -x



#Destory Existing Deployments
photon target set http://${ova_ip}:9000
photon system destroy

#Deploy Photon Controller
photon system deploy deploy-photon/manifests/photon/photon.yml 2>&1
echo "sleep 3 minutes while photon ctrlrs are starting"
sleep 160

#Target Photon Controller
PHOTON_CTRL_ID=$(photon deployment list | head -3 | tail -1)
PHOTON_CTRL_IP=$(photon deployment show $PHOTON_CTRL_ID | head -3 | tail -1 | grep -E "LoadBalancer.*28080" | awk -F " " '{print$2}')

photon target set http://${PHOTON_CTRL_IP}:9000

##Create Tenant
photon -n tenant create cf-test
photon -n tenant set cf-test

##Create Project & Link Resources
photon -n resource-ticket create --name dev-ticket --limits "vm.memory 3600 GB, vm 10000 COUNT" -t cf-test
echo 'y' | photon project create --name dev-project --limits "vm.memory 3600 GB, vm 10000 COUNT" -r dev-ticket
photon -n project set dev-project

##Upload VM & Disk  Flavours
photon flavor upload deploy-photon/manifests/photon/ephemeral-disk.yml
photon flavor upload deploy-photon/manifests/photon/persistent-disk.yml
photon flavor upload deploy-photon/manifests/photon/vm.yml
photon flavor upload deploy-photon/manifests/photon/cf-ephemeral-disk.yml

#Show Project ID
photon project show
