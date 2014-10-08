#!/bin/bash
set -x 

if [ -z "$1" ]
then
	echo USE $0 build ID
	exit 99
fi

rm -f  /var/log/nova/nova-manage.log

basedir=`dirname $0 | xargs readlink -e`
source $basedir/deployment_service_Functions.sh

#echo "passw0rd" | passwd root --stdin
rm -f /etc/yum.repos.d/*
echo "INFO: installing pre-reqs"
#yum install -y openssh-clients

export BUILDID=$1
export SC_PWD=passw0rd
export OS_PWD=passw0rd
export DOWNLOAD_ROOT=$basedir/../..
export INSTALL_LOG=$basedir/../log/$BUILDID
export BASE_URL="http://scbvt.rtp.raleigh.ibm.com/projects/s/scobvt/decibel-build/"
export SCP_INSTALL_ROOT=$basedir/../install
#export SCO_INSTALL_DIR=/root/sco/scripts/../install/IBM_Cloud_Orchestrator-2.4.0.0-D20140219-174801/
export LOCK_DIR=$basedir/../lock
#export CENTRAL_SRV1_IP=$central1_addr
#if [ -f $basedir/../lock/lock ]; then
#	echo "There is a installation running on the machine !!"
#	exit 1
#fi

#clean deployment working directories
#rm -rf $DOWNLOAD_ROOT/*
#rm -rf $INSTALL_LOG/*
rm -rf $SCP_INSTALL_ROOT/*

CURRENT_BUILD=`cat /opt/ibm/cloud-deployer/deployer.version | grep build_number | awk '{print $2}' | tr -d '"'`

EXIST_BUILD=`echo ${BUILDID##*D} | tr -d '-'`
if [ ! -z ${CURRENT_BUILD} ];then 
    if [ ${CURRENT_BUILD} -eq ${EXIST_BUILD} ];then
        echo "The current ds version with FVT version is consistent ,does not need to upgrade."
        exit 0
    fi;
fi;
#initCloud "$@"

test -d $LOCK_DIR || mkdir -p $LOCK_DIR
test -d $INSTALL_LOG || mkdir -p $INSTALL_LOG
touch $LOCK_DIR/lock

installServiceServer
if [ "$?" -ne 0 ]
then
	echo "Did not install deployment-service correctly"
	exit 93
fi

#configure the  template file
sed -i  's/CENTRAL2_ADDR/9.115.78.72/' /opt/ibm/cloud-deployer/templates/separate_compute_heat.json
sed -i  's/REGION1_ADDR/9.115.78.73/'  /opt/ibm/cloud-deployer/templates/separate_compute_heat.json
sed -i  's/eth0/eth1/' /opt/ibm/cloud-deployer/templates/separate_compute_heat.json

#rm -rf $DOWNLOAD_ROOT/*

#openstack-config --set "/etc/nova/nova.conf" "DEFAULT" "libvirt_type" "kvm"
#service openstack-nova-compute restart

sleep 10

# start to deploy allinone cloud
source /root/keystonerc 
#TODO: download image from http://9.181.26.252/SCP_VM_images/rhel64-ext3-100G.qcow2
#TODO: create the image if it does not exist
#IMAGE=`glance index | grep overcloud-img | awk '{print $1}'`
#if [ -z ${IMAGE} ];then
#    glance image-create --name overcloud-img --container-format bare --disk-format qcow2 --file /root/sco/rhel65_cldinit_dev.img
#fi;
JOB_ID=`ds job-list | grep gemini-allinone | awk '{print $2}'`
if [ -z ${JOB_ID} ];then
    ds job-create -f /opt/ibm/cloud-deployer/templates/separate_compute_heat.json gemini-allinone
    JOB_ID=`ds job-list | grep gemini-allinone | awk '{print $2}'`
    sleep 5
    ds job-execute ${JOB_ID}
else
    ds job-update -f /opt/ibm/cloud-deployer/templates/separate_compute_heat.json ${JOB_ID}
fi;

RETRY=240
while (($RETRY>0)); do
	STATUS=`ds job-list|grep ${JOB_ID}|awk '{print $6}'`
	if [ "${STATUS}" == "ERROR" ]; then
		echo "allinone job deployment failed !!"
                ds job-delete ${JOB_ID}
		exit 1
        elif [ "${STATUS}" == "FINISHED" ]; then
                echo "gemini demo job completed successfully !!"
                rm -f $LOCK_DIR/lock
                rm -f $basedir/../../IBM_Cloud_Orchestrator-2.4.0.0-${BUILDID}.tgz
                exit 0
	elif [ "${STATUS}" == "UPDATE_FINISHED" ]; then
		echo "gemini demo job completed successfully !!"
		rm -f $LOCK_DIR/lock
                rm -f $basedir/../../IBM_Cloud_Orchestrator-2.4.0.0-${BUILDID}.tgz
		exit 0
	fi
	sleep 60
        date
        STATUS=`ds job-list|grep ${JOB_ID}|awk '{print $6}'`
       let "RETRY--"
done
