#!/bin/bash
set -x 

#if [ -z "$1" ]
#then
#	echo USE $0 build ID
#	exit 99
#fi

basedir=`dirname $0 | xargs readlink -e`
source $basedir/deployment_service_Functions.sh

#echo "passw0rd" | passwd root --stdin
#rm -f /etc/yum.repos.d/*
#echo "INFO: installing pre-reqs"
#yum install -y openssh-clients

export http_proxy=http://9.115.78.100:8085/
export https_proxy=http://9.115.78.100:8085/
export BUILDID=`curl http://scbvt.rtp.raleigh.ibm.com/api/v1/results/bestproduction/d?short | grep id | cut -d':' -f 2 |  tr -d '"' | tr -d ' '`
#export BUILDID="D20140521-203703"
export SC_PWD=passw0rd
export OS_PWD=passw0rd
export DOWNLOAD_ROOT=$basedir/../builds/
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

CURRENT_BUILD=`cat /opt/ibm/cloud-deployer/ico.version | grep build_number | awk '{print $2}' | tr -d '"'`

#if [ ! -z ${CURRENT_BUILD} ];then 
#    if [ ${CURRENT_BUILD} == ${BUILDID} ];then
#        echo "The current ds version with FVT version is consistent ,does not need to upgrade."
#        exit 0
#    fi
#fi

test -d $LOCK_DIR || mkdir -p $LOCK_DIR
test -d $INSTALL_LOG || mkdir -p $INSTALL_LOG
touch $LOCK_DIR/lock

installServiceServer
if [ "$?" -ne 0 ]
then
	echo "Did not install deployment-service correctly"
	exit 93
fi

rm -rf $DOWNLOAD_ROOT/*

#rm -f /usr/lib/python2.6/site-packages/dsclient/v1/shell.py
#cp /root/sco/scripts/shell.py /usr/lib/python2.6/site-packages/dsclient/v1/shell.py

/etc/init.d/ds-engine restart
sleep 10
/etc/init.d/ds-api restart
sleep 10

source /root/keystonerc 
#CENTRAL_JOB_ID=`ds job-list | grep gemini-central | awk '{print $2}'`
#KVM_JOB_ID=`ds job-list | grep gemini-kvm | awk '{print $2}'`
#VMWARE_JOB_ID=`ds job-list | grep gemini-vmware | awk '{print $2}'`
> /var/log/ds/ds-engine.log
JOB_FAILED=0
if [ -z "$(ds node-list | grep gemini-central-1)" ];then
    echo "Please create gemini-central-1 node first!"
    exit 1
fi
if [ -z "$(ds node-list | grep gemini-central-2)" ];then
    echo "Please create gemini-central-2 node first!"
    exit 1
fi
if [ -z "$(ds node-list | grep gemini-central-3)" ];then
    echo "Please create gemini-central-3 node first!"
    exit 1
fi
CENTRAL_SERVERS_TEMPLATE_ID="$(ds template-list|grep sco-central-servers|grep -v HA|awk '{print $2}')"
CENTRAL_SERVER_1_NODEID="$(ds node-list|grep gemini-central-1|awk '{print $2}')"
CENTRAL_SERVER_1_IP="$(ds node-show $CENTRAL_SERVER_1_NODEID|grep Address|grep -v ServiceAddress|awk '{print $4}'|cut -d'"' -f2)"
CENTRAL_SERVER_2_NODEID="$(ds node-list|grep gemini-central-2|awk '{print $2}')"
CENTRAL_SERVER_2_IP="$(ds node-show $CENTRAL_SERVER_2_NODEID|grep Address|grep -v ServiceAddress|awk '{print $4}'|cut -d'"' -f2)"
CENTRAL_SERVER_3_NODEID="$(ds node-list|grep gemini-central-3|awk '{print $2}')"
CENTRAL_SERVER_3_IP="$(ds node-show $CENTRAL_SERVER_3_NODEID|grep Address|grep -v ServiceAddress|awk '{print $4}'|cut -d'"' -f2)"
CENTRAL_JOB_CREATED=false
if [ -z "$(ds job-list | grep gemini-central)" ];then
    ds job-create -t "$CENTRAL_SERVERS_TEMPLATE_ID" -N "central_server_1=$CENTRAL_SERVER_1_NODEID;central_server_2=$CENTRAL_SERVER_2_NODEID;central_server_3=$CENTRAL_SERVER_3_NODEID" -P "RegionName=RegionKVM" gemini-central-servers
    sleep 5
    if [ ! -z "$(ds job-list | grep gemini-central | grep ERROR)" ];then
       echo "gemini-central-servers job create failed!"
       cat /var/log/ds/ds-engine.log
       $JOB_FAILED=1
       exit 1 
    fi
    CENTRAL_JOB_CREATED=true
fi
CENTRAL_JOB_ID=`ds job-list | grep gemini-central | awk '{print $2}'`
for i in {gemini-central-1,gemini-central-2,gemini-central-3}; do 
    nova stop $i
    instance_name="$(nova show $i|grep instance_name|awk '{print $4}')" 
    hypervisor="$(nova show $i|grep hypervisor_hostname|awk '{print $4}')"
    sleep 5
    ssh -o StrictHostKeyChecking=no $hypervisor "virsh snapshot-revert $instance_name --current"
    sleep 10
    nova start $i
done
sleep 300
scp -o StrictHostKeyChecking=no  /root/sco/scripts/resolv.conf $CENTRAL_SERVER_1_IP:/etc/resolv.conf
scp -o StrictHostKeyChecking=no  /root/sco/scripts/resolv.conf $CENTRAL_SERVER_2_IP:/etc/resolv.conf
scp -o StrictHostKeyChecking=no  /root/sco/scripts/resolv.conf $CENTRAL_SERVER_3_IP:/etc/resolv.conf
#ssh -o StrictHostKeyChecking=no $CENTRAL_SERVER_1_IP 'echo "nameserver 9.0.148.50" >> /etc/resolv.conf; mkdir -p /etc/chef/'
scp -o StrictHostKeyChecking=no  /etc/chef/databag_secret $CENTRAL_SERVER_1_IP:/etc/chef/
#scp -o StrictHostKeyChecking=no  /root/sco/scripts/hosts $CENTRAL_SERVER_1_IP:/etc/hosts
#ssh -o StrictHostKeyChecking=no $CENTRAL_SERVER_2_IP 'echo "nameserver 9.0.148.50" >> /etc/resolv.conf; mkdir -p /etc/chef/'
scp -o StrictHostKeyChecking=no  /etc/chef/databag_secret $CENTRAL_SERVER_2_IP:/etc/chef/
#scp -o StrictHostKeyChecking=no  /root/sco/scripts/hosts $CENTRAL_SERVER_1_IP:/etc/hosts
#ssh -o StrictHostKeyChecking=no $CENTRAL_SERVER_3_IP 'echo "nameserver 9.0.148.50" >> /etc/resolv.conf; mkdir -p /etc/chef/'
scp -o StrictHostKeyChecking=no  /etc/chef/databag_secret $CENTRAL_SERVER_3_IP:/etc/chef/
#scp -o StrictHostKeyChecking=no  /root/sco/scripts/hosts $CENTRAL_SERVER_1_IP:/etc/hosts
if $CENTRAL_JOB_CREATED; then
   ds job-execute $CENTRAL_JOB_ID
else
   ds job-update $CENTRAL_JOB_ID
fi
while true; do
    CENTRAL_JOB_STATUS=$(ds job-list | grep gemini-central | awk '{print $6}')
    if [[ $? -ne 0 || "$CENTRAL_JOB_STATUS" == "ERROR" ]]; then
	echo "Central servers deployment failed !"
        cat /var/log/ds/ds-engine.log
	exit 2
    fi
    sleep 300
done

KVM_REGION_TEMPLATE_ID="$(ds template-list|grep kvm_region-with-compute-neutron|grep -v HA|awk '{print $2}')"
KVM_NEUTRON_NODEID="$(ds node-list|grep gemini-kvm-neutron|awk '{print $2}')"
KVM_NEUTRON_IP="$(ds node-show $KVM_NEUTRON_NODEID|grep Address|grep -v ServiceAddress|awk '{print $4}'|cut -d'"' -f2)"
KVM_REGION_NODEID="$(ds node-list|grep gemini-kvm-region|awk '{print $2}')"
KVM_REGION_IP="$(ds node-show $KVM_REGION_NODEID|grep Address|grep -v ServiceAddress|awk '{print $4}'|cut -d'"' -f2)"
KVM_COMPUTE_NODEID="$(ds node-list|grep gemini-kvm-compute|awk '{print $2}')"
KVM_JOB_CREATED=false
if [ -z "$(ds job-list | grep gemini-kvm)" ];then
    ds job-create -t "$KVM_REGION_TEMPLATE_ID" -N "kvm_region_neutron=$KVM_REGION_NODEID;kvm_compute=$KVM_COMPUTE_NODEID;neutron_network_node=$KVM_NEUTRON_NODEID" -P "ExtNetInterface=eth1;VniRange=10000:20000;VxlanMultiCastGroup=224.0.0.200;RegionName=RegionKVM" -p "$CENTRAL_JOB_ID" gemini-kvm-neutron
    sleep 5
    if [ ! -z "$(ds job-list | grep gemini-kvm | grep ERROR)" ];then
       echo "gemini-kvm-neutron job create failed!"
       cat /var/log/ds/ds-engine.log
       exit 3
    fi
    KVM_JOB_CREATED=true
fi
KVM_JOB_ID=`ds job-list | grep gemini-kvm | awk '{print $2}'`
for i in {gemini-kvm-region-p1,gemini-kvm-neutron}; do 
    nova stop $i
    instance_name="$(nova show $i|grep instance_name|awk '{print $4}')" 
    hypervisor="$(nova show $i|grep hypervisor_hostname|awk '{print $4}')"
    sleep 5
    ssh -o StrictHostKeyChecking=no $hypervisor "virsh snapshot-revert $instance_name --current"
    sleep 10
    nova start $i
done
sleep 300
scp -o StrictHostKeyChecking=no  /root/sco/scripts/resolv.conf $KVM_REGION_IP:/etc/resolv.conf
scp -o StrictHostKeyChecking=no  /root/sco/scripts/resolv.conf $KVM_NEUTRON_NODEID:/etc/resolv.conf
#ssh -o StrictHostKeyChecking=no $KVM_NEUTRON_IP 'echo "nameserver 9.0.148.50" >> /etc/resolv.conf; mkdir -p /etc/chef/'
#scp -o StrictHostKeyChecking=no  /etc/chef/databag_secret $KVM_NEUTRON_IP:/etc/chef/
#ssh -o StrictHostKeyChecking=no $KVM_REGION_IP 'echo "nameserver 9.0.148.50" >> /etc/resolv.conf; mkdir -p /etc/chef/'
#scp -o StrictHostKeyChecking=no  /etc/chef/databag_secret $KVM_REGION_IP:/etc/chef/
#ds job-execute $KVM_JOB_ID
if $KVM_JOB_CREATED; then
   ds job-execute $KVM_JOB_ID
else
   ds job-update $KVM_JOB_ID
fi
while true; do
    KVM_JOB_STATUS=$(ds job-list | grep gemini-kvm | awk '{print $6}')
    if [[ $? -ne 0 || "$CENTRAL_JOB_STATUS" == "ERROR" ]]; then
        echo "KVM region deployment failed !"
        cat /var/log/ds/ds-engine.log
	break
    fi
    sleep 300
done

VMWARE_REGION_TEMPLATE_ID="$(ds template-list|grep vmware_region_neutron|grep -v HA|awk '{print $2}')"
VMWARE_REGION_NODEID="$(ds node-list|grep gemini-vmware-region|awk '{print $2}')"
VMWARE_REGION_IP="$(ds node-show $VMWARE_REGION_NODEID|grep Address|grep -v ServiceAddress|awk '{print $4}'|cut -d'"' -f2)"
VMWARE_NEUTRON_NODEID="$(ds node-list|grep gemini-vmware-neutron|awk '{print $2}')"
VMWARE_NEUTRON_IP="$(ds node-show $VMWARE_NEUTRON_NODEID|grep Address|grep -v ServiceAddress|awk '{print $4}'|cut -d'"' -f2)"
VMWARE_JOB_CREATED=false
if [ -z "$(ds job-list | grep gemini-vmware)" ];then
    ds job-create -t "$VMWARE_REGION_TEMPLATE_ID" -P  "VMHostIP=9.115.78.69;VMHostPassword=passw0rd;VMHostUserName=root;VMServerHost=9.115.78.69;VMServerPassword=passw0rd;VMServerUserName=root;VMDataCenterPath=gemini-cluster;VMDataStoreName=cloud-ds1;VniRange=10000:20000;VxlanMultiCastGroup=224.0.0.200;RegionName=RegionVMware"  -N "neutron_network_node=$VMWARE_NEUTRON_NODEID;vmware_region_server=$VMWARE_REGION_NODEID" -p "$CENTRAL_JOB_ID" gemini-vmware-neutron
    sleep 5
    if [ ! -z "$(ds job-list | grep gemini-vmware | grep ERROR)" ];then
       echo "gemini-vmware-neutron job create failed!"
       cat /var/log/ds/ds-engine.log
       exit 5
    fi
    VMWARE_JOB_CREATED=true
fi
VMWARE_JOB_ID=`ds job-list | grep gemini-vmware | awk '{print $2}'`
for i in {gemini-vmware-region,gemini-vmware-neutron}; do 
    nova stop $i
    instance_name="$(nova show $i|grep instance_name|awk '{print $4}')" 
    hypervisor="$(nova show $i|grep hypervisor_hostname|awk '{print $4}')"
    sleep 5
    ssh -o StrictHostKeyChecking=no $hypervisor "virsh snapshot-revert $instance_name --current"
    sleep 10
    nova start $i
done
sleep 300
scp -o StrictHostKeyChecking=no  /root/sco/scripts/resolv.conf $VMWARE_REGION_IP:/etc/resolv.conf
scp -o StrictHostKeyChecking=no  /root/sco/scripts/resolv.conf $VMWARE_NEUTRON_IP:/etc/resolv.conf
#ssh -o StrictHostKeyChecking=no $VMWARE_NEUTRON_IP 'echo "nameserver 9.0.148.50" >> /etc/resolv.conf; mkdir -p /etc/chef/'
#scp -o StrictHostKeyChecking=no  /etc/chef/databag_secret $VMWARE_NEUTRON_IP:/etc/chef/
#ssh -o StrictHostKeyChecking=no $VMWARE_REGION_IP 'echo "nameserver 9.0.148.50" >> /etc/resolv.conf; mkdir -p /etc/chef/'
#scp -o StrictHostKeyChecking=no  /etc/chef/databag_secret $VMWARE_REGION_IP:/etc/chef/
#ds job-execute $VMWARE_JOB_ID
if $VMWARE_JOB_CREATED; then
   ds job-execute $VMWARE_JOB_ID
else
   ds job-update $VMWARE_JOB_ID
fi
while true; do
    KVM_JOB_STATUS=$(ds job-list | grep gemini-kvm | awk '{print $6}')
    if [[ $? -ne 0 || "$CENTRAL_JOB_STATUS" == "ERROR" ]]; then
        echo "VMWare region deployment failed !"
        cat /var/log/ds/ds-engine.log
	break
    fi
    sleep 300
done

cat /var/log/ds/ds-engine.log

exit 0

