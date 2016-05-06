#!/bin/bash +x

# function to parse one ip or one ip range
function parseIP() {
	IFS='-' read -r -a RANGESPLIT <<< "$1"
	SIZE=${#RANGESPLIT[@]}
	if (( ${SIZE} > 2 || ${SIZE} < 1 )); then
	    echo "null"
        exit 1
	fi
	prips ${RANGESPLIT[0]} ${RANGESPLIT[${SIZE}-1]} 2>/dev/null || echo "null"
}



if [ $arg_wipe == "wipe" ];
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
done

#Detect & Clean DataStore(s)
if [ ! -f deploy-photon/manifests/photon/$photon_manifest ]; then
    echo "Error: Photon Manifest not found!  I got this value for \$photon_manifest="$photon_manifest
    exit 1
fi

# How Many Hosts subvalues exist in the Manifest
HOST_COUNT=$(cat deploy-photon/manifests/photon/$photon_manifest | shyaml get-values hosts | grep address_ranges | wc -l)

for (( x=${HOST_COUNT}-1; x>=0; x--)); do
    declare -a HOSTS=()
    declare -a DATASTORES=()

    # Use shyaml to get all hosts in each host block
    declare -a VALS=()
    VALS+=(hosts.$x.address_ranges)
    for (( y=${#VALS[@]}-1; y>=0; y--)); do
        TEMPVAL=$(cat deploy-photon/manifests/photon/$photon_manifest | shyaml get-values ${VALS[$y]} 2>/dev/null || \
                  cat deploy-photon/manifests/photon/$photon_manifest | shyaml get-value ${VALS[$y]} 2>/dev/null || echo "null")
        if [[ $TEMPVAL =~ ^.*\,.*$ ]]; then
            IFS=',' read -r -a TEMPVALSPLIT <<< "$TEMPVAL"
            for (( z=${#TEMPVALSPLIT[@]}-1; z>=0; z--)); do
                HOSTS+=($(parseIP "${TEMPVALSPLIT[$z]}"))
            done
        else
            HOSTS+=($(parseIP "${TEMPVAL}"))
        fi
    done

    # Use shyaml to get all datastores in each host block
    declare -a VALS=()
    VALS+=(deployment.image_datastores)
    VALS+=(hosts.$x.metadata.MANAGEMENT_DATASTORE)
    VALS+=(hosts.$x.metadata.ALLOWED_DATASTORES)
    for (( y=${#VALS[@]}-1; y>=0; y--)); do
        TEMPVAL=$(cat deploy-photon/manifests/photon/$photon_manifest | shyaml get-values ${VALS[$y]} 2>/dev/null || \
                  cat deploy-photon/manifests/photon/$photon_manifest | shyaml get-value ${VALS[$y]} 2>/dev/null || echo "null")
        # If no ALLOWED_DATASTORES, clean up all datastores
        if [[ ${y} -eq $((${#VALS[@]}-1)) && ${TEMPVAL} == "null" ]]; then
            break
        fi
        if [[ $TEMPVAL =~ ^.*\,.*$ ]]; then
            IFS=',' read -r -a TEMPVALSPLIT <<< "$TEMPVAL"
            for (( z=${#TEMPVALSPLIT[@]}-1; z>=0; z--)); do
                DATASTORES+=(${TEMPVALSPLIT[$z]})
            done
        else
            DATASTORES+=(${TEMPVAL})
        fi
    done

    # Sort to Unique Values
    HOSTS=($(printf "%s\n" "${HOSTS[@]}" | sort -u | grep -v null))
    DATASTORES=($(printf "%s\n" "${DATASTORES[@]}" | sort -u | grep -v null))

    # Clean Datastores
    for h in ${HOSTS[@]}; do
        if [ ${#DATASTORES[@]} -eq 0 ]; then
            DATASTORES+=($(vifs --server $h --username $ESX_USER --password $ESX_PASSWD --listds | sed 1,4d))
        fi
        for d in ${DATASTORES[@]}; do
            echo "cleaning up datastore ${d} on host ${h}"
            vifs --server $h --username $ESX_USER --password $ESX_PASSWD --rm  "[$d] disks" --force || echo "Already Wiped"
            vifs --server $h --username $ESX_USER --password $ESX_PASSWD --rm  "[$d] tmp_images" --force || echo "Already Wiped"
            vifs --server $h --username $ESX_USER --password $ESX_PASSWD --rm  "[$d] tmp_uploads" --force || echo "Already Wiped"
            vifs --server $h --username $ESX_USER --password $ESX_PASSWD --rm  "[$d] images" --force || echo "Already Wiped"
            vifs --server $h --username $ESX_USER --password $ESX_PASSWD --rm  "[$d] vms" --force || echo "Already Wiped"
            vifs --server $h --username $ESX_USER --password $ESX_PASSWD --rm  "[$d] vibs" --force || echo "Already Wiped"
            vifs --server $h --username $ESX_USER --password $ESX_PASSWD --rm  "[$d] deleted_images" --force || echo "Already Wiped"
        done
    done
done
