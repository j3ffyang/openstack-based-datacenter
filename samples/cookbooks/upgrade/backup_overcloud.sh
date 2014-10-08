#!/bin/bash

usage()
{
cat << EOF
Backup VMs launched by under cloud, This script should be run on deployment service node, VM name should be 'production*'
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

tmp_file=`mktemp -p ${current_dir}`
nova list | grep "production" | awk '{print $2,$4}' > ${tmp_file}

while read server_id server_name
  do
    server_id_tmp=`nova image-list | grep ${server_name}${suffix} | awk '{print $8}'`
    if [ "${server_id_tmp}" = "${server_id}" ]; then
        echo "VM $server_id is already backuped"
        continue
    fi
    echo "Start backup VM: $server_id to ${server_name}${suffix}"
	nova image-create ${server_id} ${server_name}${suffix}
	if [ $? -ne 0 ]; then
    	echo "Backup VM ${server_id} failed. EXIT !!!"
    	rm -rf ${tmp_file}
      	exit -1
    fi
    
    DATE=`date +%s`
    flag=
	while (($[`date +%s` - ${DATE}]<300))
	  do
	    echo "Wait for backup VM completes..."
	    status=`nova image-list | grep ${server_name}${suffix} | awk '{print $6}'`
	    if [ ${status} = "ACTIVE" ];then
	        echo "Backup VM $server_id to ${server_name}${suffix} succeeded"
	        flag=true
	        break
	    fi
	    if [ ${status} = "ERROR" ];then
	        echo "Backup VM $server_id to ${server_name}${suffix} failed"
	        flag=true
	        rm -rf ${tmp_file}
	        exit -1
	    fi
	   sleep 10
	done
	
	if [ -z ${flag} ]; then
		echo "Backup VM $server_id to ${server_name}${suffix} has not finished after 5 mins, exit"
        rm -rf ${tmp_file}
        exit -1
    fi
done <${tmp_file}

rm -rf ${tmp_file}