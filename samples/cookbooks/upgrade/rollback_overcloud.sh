#!/bin/bash

usage()
{
cat << EOF
Rollback VMs launched by under cloud, This script should be run on deployment service node. VM name should be 'production*'
Usage: $0 <-s>
OPTIONS:
   -h      Show this message.
   -s      Build label as suffix of the created image name
EOF
}

current_dir=`dirname $0 | xargs readlink -e`

while getopts “hs:” OPTION
do
     case $OPTION in
         h)
             usage
             exit -1
             ;;
         s)
             suffix=$OPTARG
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

if [ -z "${suffix}" ]; then
        echo "ERROR: -s options are required" 1>&2
        usage
        exit -1
fi

source /root/openrc

tmp_vm_list=`mktemp -p ${current_dir}`
nova list | grep "production" | awk '{print $2,$4}' > ${tmp_vm_list}
tmp_image_list=`mktemp -p ${current_dir}`
nova image-list | grep ${suffix} | awk '{print $2,$4,$8}' > ${tmp_image_list}

while read server_id server_name
  do
    echo "Start suspend VM: ${server_id} ${server_name}"
    status=`nova list | grep ${server_id} | awk '{print $6}'`
    if [ ${status} = "SUSPENDED" ];then
        echo "Server ${server_id} is already suspended"
    else
        nova suspend ${server_id}
    fi
	if [ $? -ne 0 ]; then
    	echo "Suspending VM ${server_id} failed. EXIT !!!"
    	rm -rf ${tmp_vm_list} ${tmp_image_list}
      	exit -1
    fi    
    DATE=`date +%s`
    flag=
	while (($[`date +%s` - ${DATE}]<300))
	  do
	    echo "Wait for suspending VM completes..."
	    status=`nova list | grep ${server_id} | awk '{print $6}'`
	    if [ ${status} = "SUSPENDED" ];then
	        echo "Suspending VM $server_id succeeded"
	        flag=true
	        break
	    fi
	    if [ ${status} = "ERROR" ];then
	        echo "Suspending VM $server_id failed"
	        flag=true
	        rm -rf ${tmp_vm_list} ${tmp_image_list}
	        exit -1
	    fi
	 sleep 10
	done	
	if [ -z ${flag} ]; then
		echo "Suspending VM $server_id has not finished after 5 mins, exit"
        rm -rf ${tmp_vm_list} ${tmp_image_list}
        exit -1
    fi

    image_id=`cat ${tmp_image_list} | grep ${server_id} | awk '{print $1}'`
    echo "Start booting VM ${server_id} ${server_name} from image ${image_id}"
    flavor_id=`nova show ${server_id}  | grep "flavor" | awk '{print $4}'`
    ip_addr=`nova show ${server_id} | grep network | awk '{print $5}'`
    net_name=`nova show ${server_id} | grep network | awk '{print $2}'`
    net_id=`nova net-list | grep ${net_name} | awk '{print $2}'`
    echo "Boot new VM using command: nova boot --image ${image_id} --flavor ${flavor_id} --nic net-id=${net_id},v4-fixed-ip=${ip_addr} ${server_name}"
    nova boot --image ${image_id} --flavor ${flavor_id} --nic net-id=${net_id},v4-fixed-ip=${ip_addr} ${server_name}
    if [ $? -ne 0 ]; then
        echo "Booting VM from image ${image_id} failed. EXIT !!!"
        rm -rf ${tmp_vm_list} ${tmp_image_list}
        exit -1
    fi
    new_server_id=`nova list | grep -v "SUSPENDED" | grep ${server_name} | awk '{print $2}'`
    DATE=`date +%s`
    flag=
    while (($[`date +%s` - ${DATE}]<300))
      do
        echo "Wait for VM booting completes..."
        status=`nova list | grep ${new_server_id} | awk '{print $6}'`
        if [ ${status} = "ACTIVE" ];then
            echo "Boot VM $new_server_id succeeded"
            flag=true
            break
        fi
        if [ ${status} = "ERROR" ];then
            echo "Boot VM $new_server_id failed"
            flag=true
            rm -rf ${tmp_vm_list} ${tmp_image_list}
            exit -1
        fi
     sleep 10
    done    
    if [ -z ${flag} ]; then
        echo "Boot VM $new_server_id has not finished after 5 mins, exit"
        rm -rf ${tmp_vm_list} ${tmp_image_list}
        exit -1
    fi

    echo "Delete old VM ${server_id} ${server_name} since rollback of ${server_name} succeeded"
    nova delete ${server_id}
done <${tmp_vm_list}

rm -rf ${tmp_vm_list} ${tmp_image_list}