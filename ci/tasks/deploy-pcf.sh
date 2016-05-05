#!/bin/bash

#TMP DEBUG VARS
#pcf_pivnet_token=w5xBrSWhbiPwKxL95y_e
#bosh_deployment_network_ip="192.168.100.9"
#bosh_deployment_user=admin
#bosh_deployment_passwd=admin
################

if [ -z $1 ] ; then
        >2& echo "ARG ERROR, deploy-pcf.sh needs something to install"
  >2& echo "usage:  deploy-pcf.sh [ pivnet_release_name ] [ version | latest ]"
        >2& echo "example: deploy-pcf.sh elastic-runtime latest"
        exit 1
fi


# If latest version is asked for, grab it from Pivnet else look for the givent version

if [[ $2 == "latest" ]]; then
    PIVNET_REL_ID=$(curl -s -X GET https://network.pivotal.io/api/v2/products/$1/releases | jq '[.releases[].id] | max')
else
    CMD="curl -s -X GET https://network.pivotal.io/api/v2/products/$1/releases | jq ' .releases[] | select(.version == \"$2\") | .id'"
    PIVNET_REL_ID=$(eval $CMD)
fi

# Get Download Link

case $1 in
  elastic-runtime)
    DOWNLOAD_NAME="PCF Elastic Runtime"
    ;;
  *)
    echo "deploy-pcf.sh doesnt support $1 "
    exit 1
esac

CMD="curl -s -X GET https://network.pivotal.io/api/v2/products/$1/releases/$PIVNET_REL_ID/product_files | jq ' .product_files[] | select(.name == \"$DOWNLOAD_NAME\") | ._links.download.href'"
PIVNET_LINK=$(eval $CMD | tr -d '"')

# Download and Unpack Tile

WORKER_ROOT=$(pwd)
mkdir /tmp/$1
cd /tmp/$1

echo "Downloading $1 $2 version from $PIVNET_LINK ..."
  curl -H "Authorization: Token ${pcf_pivnet_token}"  -X POST https://network.pivotal.io/api/v2/products/$1/releases/$PIVNET_REL_ID/eula_acceptance
  echo
  wget -O /tmp/${1}/${1}-${2}.pivotal --post-data="" --header="Authorization: Token ${pcf_pivnet_token}" ${PIVNET_LINK}

unzip ${1}-${2}.pivotal
cd /tmp/$1/releases

# Upload Releases to BOSH
bosh -n target https://${bosh_deployment_network_ip}
bosh -n login ${bosh_deployment_user} ${bosh_deployment_passwd}

cd /tmp/$1/releases
for f in `ls` ; do
  bosh -n upload release $f
done
