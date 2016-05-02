#!/bin/bash -x

#### Build the latest Photon CPI
cd bosh-photon-cpi-release
bosh create release releases/bosh-photon-cpi/bosh-photon-cpi-0.8.0.u1.yml
cd ..

#### Get Photon Project Target
photon target set http://${ova_ip}:9000
PHOTON_CTRL_ID=$(photon deployment list | head -3 | tail -1)
PHOTON_CTRL_IP=$(photon deployment show $PHOTON_CTRL_ID | grep -E "LoadBalancer.*28080" | awk -F " " '{print$2}')
photon target set http://${PHOTON_CTRL_IP}:9000
photon tenant set cf-test
photon project set dev-project
PHOTON_PROJ=$(photon project list | head -3 | tail -1 | awk -F " " '{print$1}')

#### Create Flavors for CF
# 000's - ultra small VMs
# 1 cpu, 8MB memory
photon -n flavor create -n core-10 -k vm -c "vm.cpu 1 COUNT,vm.memory 32 MB"
# 100's - entry level, non-production sla only
# 1 cpu, 2GB memory, vm.cost = 1.0 baseline
photon -n flavor create -n core-100 -k vm -c "vm.cpu 1 COUNT,vm.memory 2 GB"
# 1 cpu, 4GB memory, vm.cost = 1.5 baseline
# intention is ~parity with GCE n1-standard-1 (ephemeral root)
photon -n flavor create -n core-110 -k vm -c "vm.cpu 1 COUNT,vm.memory 4 GB"
# 200's - entry level production class vm's in an HA environment
# 2 cpu, 4GB memory, vm.cost 2.0
photon -n flavor create -n core-200 -k vm -c "vm.cpu 2 COUNT,vm.memory 4 GB"
# 2 cpu, 8GB memory, vm.cost 4.0
# intention is ~parity with GCE n1-standard-2 (ephemeral root)
photon -n flavor create -n core-220 -k vm -c "vm.cpu 2 COUNT,vm.memory 8 GB"
# 4 cpu, 16GB memory, vm.cost 12.0
# intention is ~parity with GCE n1-standard-4 (ephemeral root)
photon -n flavor create -n core-240 -k vm -c "vm.cpu 2 COUNT,vm.memory 16 GB"
# 4 cpu, 32GB memory, vm.cost 20.0
photon -n flavor create -n core-245 -k vm -c "vm.cpu 2 COUNT,vm.memory 32 GB"
# 8 cpu, 32GB memory, vm.cost 25.0
# intention is ~parity with GCE n1-standard-8 (ephemeral root)
photon -n flavor create -n core-280 -k vm -c "vm.cpu 8 COUNT,vm.memory 32 GB"
# 8 cpu, 64GB memory, vm.cost 48.0
# intention is ~parity with GCE n1-standard-8 (ephemeral root)
photon -n flavor create -n core-285 -k vm -c "vm.cpu 8 COUNT,vm.memory 64 GB"
# flavor used for failure test
photon -n flavor create -n huge-vm -k vm -c "vm.cpu 8000 COUNT,vm.memory 9000 GB"
## disks
photon -n flavor create -n pcf-2 -k ephemeral-disk -c "ephemeral-disk 1 COUNT,ephemeral-disk.capacity 2 GB"
photon -n flavor create -n pcf-4 -k ephemeral-disk -c "ephemeral-disk 1 COUNT,ephemeral-disk.capacity 4 GB"
photon -n flavor create -n pcf-20 -k ephemeral-disk -c "ephemeral-disk 1 COUNT,ephemeral-disk.capacity 20 GB"
photon -n flavor create -n pcf-100 -k ephemeral-disk -c "ephemeral-disk 1 COUNT,ephemeral-disk.capacity 100 GB"
photon -n flavor create -n pcf-16 -k ephemeral-disk -c "ephemeral-disk 1 COUNT,ephemeral-disk.capacity 16 GB"
photon -n flavor create -n pcf-32 -k ephemeral-disk -c "ephemeral-disk 1 COUNT,ephemeral-disk.capacity 32 GB"
photon -n flavor create -n pcf-64 -k ephemeral-disk -c "ephemeral-disk 1 COUNT,ephemeral-disk.capacity 64 GB"
photon -n flavor create -n pcf-128 -k ephemeral-disk -c "ephemeral-disk 1 COUNT,ephemeral-disk.capacity 128 GB"
photon -n flavor create -n pcf-256 -k ephemeral-disk -c "ephemeral-disk 1 COUNT,ephemeral-disk.capacity 256 GB"
photon -n flavor create -n core-100 -k persistent-disk -c "persistent-disk 1 COUNT"
photon -n flavor create -n core-200 -k persistent-disk -c "persistent-disk 1 COUNT"
photon -n flavor create -n core-300 -k persistent-disk -c "persistent-disk 1 COUNT"


#### Wipe Any Previous Bosh init state
rm -rf ~/.bosh_init || "Already Gone"
rm -rf bosh-state.json  || "Already Gone"

#### Edit Bosh Manifest & Deploy BOSH
cp deploy-photon/manifests/bosh/bosh.yml /tmp/bosh.yml
perl -pi -e "s/PHOTON_PROJ/$PHOTON_PROJ/g" /tmp/bosh.yml
perl -pi -e "s/PHOTON_CTRL_IP/$PHOTON_CTRL_IP/g" /tmp/bosh.yml
bosh-init deploy /tmp/bosh.yml

#### Use the Same Stemcell in the manifest & Upload it for all CF/Service Deployments
STEMCELL="3232.1"
wget https://d26ekeud912fhb.cloudfront.net/bosh-stemcell/vsphere/bosh-stemcell-$STEMCELL-vsphere-esxi-ubuntu-trusty-go_agent.tgz -O /tmp/bosh-stemcell-$STEMCELL-vsphere-esxi-ubuntu-trusty-go_agent.tgz

BOSH_TARGET=`cat deploy-photon/manifests/bosh/bosh.yml | grep -A6 "jobs:" | grep static_ips | awk -F ":" '{print$2}' | tr -d '[]' | tr -d ' '`
bosh -n target https://${BOSH_TARGET}
bosh -n login admin admin

bosh upload stemcell /tmp/bosh-stemcell-$STEMCELL-vsphere-esxi-ubuntu-trusty-go_agent.tgz
