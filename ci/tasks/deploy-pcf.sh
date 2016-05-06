#!/bin/bash
set -e

if [ ! -f manifests/pcf/${pcf_manifest} ]; then
  echo "ERROR, Can't find ERT Manifest"
  exit 1
fi

bosh -n target https://${bosh_deployment_network_ip}
bosh -n login ${bosh_deployment_user} ${bosh_deployment_passwd}

bosh deployment manifests/pcf/${pcf_manifest}
bosh -n deploy
