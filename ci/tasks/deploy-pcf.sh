#!/bin/bash -x
if [ -z $1 ] ; then
	>2& echo "ERROR, need something to install"
	>2& echo "example: deploy-pcf.sh ert latest"
	exit 1
fi

echo $1
echo $2
