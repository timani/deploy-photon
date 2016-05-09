#!/bin/bash
set -e

if [ ! -f deploy-photon/manifests/pcf/${pcf_manifest} ]; then
  echo "ERROR, Can't find ERT Manifest ${pcf_manifest}"
  exit 1
fi

bosh -n target https://${bosh_deployment_network_ip}
bosh -n login ${bosh_deployment_user} ${bosh_deployment_passwd}

cp deploy-photon/manifests/pcf/${pcf_manifest} /tmp/${pcf_manifest}

perl -pi -e "s/ignore/`bosh status --uuid`/g" /tmp/${pcf_manifest}

bosh deployment /tmp/${pcf_manifest}
bosh -n deploy
