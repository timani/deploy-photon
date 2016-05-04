#!/bin/bash -x
set -e

#### Build the Photon CPI and get sha1
if [[ $photon_release == "latest" || -z $photon_release ]]; then
        CPI_FILE=$(ls bosh-photon-cpi-release/releases/bosh-photon-cpi/bosh-photon-cpi-*.yml | sort | head -1)
else
        CPI_FILE=$(ls bosh-photon-cpi-release/releases/bosh-photon-cpi/bosh-photon-cpi-$photon_release.yml | sort | head -1)
fi
cd bosh-photon-cpi-release
CPI_RELEASE=$(bosh create release ../$CPI_FILE | grep Generated | awk -F " " '{print$2}')
cd ..
CPI_SHA1=$(openssl sha1 $CPI_RELEASE | awk -F "= " '{print$2}')

#### Get Photon Project Target
photon target set http://${ova_ip}:9000
PHOTON_CTRL_ID=$(photon deployment list | head -3 | tail -1)
PHOTON_CTRL_IP=$(photon deployment show $PHOTON_CTRL_ID | grep -E "LoadBalancer.*28080" | awk -F " " '{print$2}')
photon target set http://${PHOTON_CTRL_IP}:9000
photon tenant set $photon_tenant
photon project set $photon_project
PHOTON_PROJ_ID=$(photon project list | $photon_project |  awk -F " " '{print$1}')

#### Create Photon Flavors for PCF
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
photon -n flavor create -n core-100 -k ephemeral-disk -c "ephemeral-disk 1 COUNT"
photon -n flavor create -n core-200 -k ephemeral-disk -c "ephemeral-disk 1 COUNT"
photon -n flavor create -n core-300 -k ephemeral-disk -c "ephemeral-disk 1 COUNT"
photon -n flavor create -n core-100 -k persistent-disk -c "persistent-disk 1 COUNT"
photon -n flavor create -n core-200 -k persistent-disk -c "persistent-disk 1 COUNT"
photon -n flavor create -n core-300 -k persistent-disk -c "persistent-disk 1 COUNT"


#### Create Photon Network
photon network create -n $bosh_deployment_network -p $bosh_deployment_network -d "BOSH Deployment Network" || echo "$bosh_deployment_network Already Exists"
BOSH_DEPLOYMENT_NETWORK_ID=$(photon network list | grep $bosh_deployment_network | awk -F " " '{print$1}')

#### Edit Bosh Manifest & Deploy BOSH

if [ ! -f deploy-photon/manifests/bosh/$bosh_manifest ]; then
    echo "Error: Bosh Manifest not found in deploy-photon/manifests/bosh/ !!!  I got this value for \$bosh_manifest="$bosh_manifest
    exit 1
fi

# Set Photon Specific Deployment Object IDs in BOSH Manifest
cp deploy-photon/manifests/bosh/$bosh_manifest /tmp/bosh.yml

CPI_RELEASE_REGEX=$(echo $CPI_RELEASE | sed 's|/|\\\/|g')
BOSH_DEPLOYMENT_NETWORK_SUBNET_REGEX=$(echo $bosh_deployment_network_subnet | sed 's|/|\\\/|g' | sed 's|\.|\\\.|g')

perl -pi -e "s/PHOTON_PROJ_ID/$PHOTON_PROJ_ID/g" /tmp/bosh.yml
perl -pi -e "s/PHOTON_CTRL_IP/$PHOTON_CTRL_IP/g" /tmp/bosh.yml
perl -pi -e "s/CPI_SHA1/$CPI_SHA1/g" /tmp/bosh.yml
perl -pi -e "s/CPI_RELEASE/$CPI_RELEASE_REGEX/g" /tmp/bosh.yml
perl -pi -e "s/BOSH_DEPLOYMENT_NETWORK_ID/$BOSH_DEPLOYMENT_NETWORK_ID/g" /tmp/bosh.yml
perl -pi -e "s/BOSH_DEPLOYMENT_NETWORK_SUBNET/$BOSH_DEPLOYMENT_NETWORK_SUBNET_REGEX/g" /tmp/bosh.yml
perl -pi -e "s/BOSH_DEPLOYMENT_NETWORK_GW/$bosh_deployment_network_gw/g" /tmp/bosh.yml
perl -pi -e "s/BOSH_DEPLOYMENT_NETWORK_DNS/$bosh_deployment_network_dns/g" /tmp/bosh.yml
perl -pi -e "s/BOSH_DEPLOYMENT_NETWORK_IP/$bosh_deployment_network_ip/g" /tmp/bosh.yml

# Deploy BOSH
bosh-init deploy /tmp/bosh.yml

# Target Bosh and test Status Reply
echo "sleep 3 minutes while BOSH starts..."
sleep 180
BOSH_TARGET=$(cat /tmp/bosh.yml | shyaml get-values jobs.0.networks.0.static_ips)
BOSH_LOGIN=$(cat /tmp/bosh.yml | shyaml get-value jobs.0.properties.director.user_management.local.users.0.name)
BOSH_PASSWD=$(cat /tmp/bosh.yml | shyaml get-value jobs.0.properties.director.user_management.local.users.0.password)
bosh -n target https://${BOSH_TARGET}
bosh -n login ${BOSH_LOGIN} ${BOSH_PASSWD}
bosh status
