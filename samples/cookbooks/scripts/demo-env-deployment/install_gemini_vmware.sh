#!/bin/bash
set -x 

CURRENT_BUILD=`cat /opt/ibm/cloud-deployer/ico.version | grep build_number | awk '{print $2}' | tr -d '"'`
echo "The build version is: $CURRENT_BUILD"

source /root/keystonerc
> /var/log/ds/ds-engine.log
if [ -z "$(ds job-list | grep gemini-central)" ];then
    echo "Please deployment Central Servers first !!"
    exit 1
fi
CENTRAL_JOB_ID=`ds job-list | grep gemini-central | awk '{print $2}'`

if [ -z "$(ds node-list | grep gemini-vmware-region)" ];then
    ds node-create -p "{Port: 22, Password: passw0rd, User: root, Address: 9.115.78.104, Fqdn: gemini-vmware-region.gemini.cdl.ibm.com}" -t "IBM::SCO::Node" gemini-vmware-region
fi
if [ -z "$(ds node-list | grep gemini-vmware-neutron)" ];then
    ds node-create -p "{Port: 22, Password: passw0rd, User: root, Address: 9.115.78.103, Fqdn: gemini-vmware-neutron.gemini.cdl.ibm.com}" -t "IBM::SCO::Node" gemini-vmware-neutron
fi

VMWARE_REGION_TEMPLATE_ID="$(ds template-list|grep vmware_region_neutron|grep -v HA|grep -v sharedb|awk '{print $2}')"
VMWARE_REGION_NODEID="$(ds node-list|grep gemini-vmware-region|awk '{print $2}')"
VMWARE_REGION_IP="$(ds node-show $VMWARE_REGION_NODEID|grep Address|grep -v ServiceAddress|awk '{print $4}'|cut -d'"' -f2)"
VMWARE_NEUTRON_NODEID="$(ds node-list|grep gemini-vmware-neutron|awk '{print $2}')"
VMWARE_NEUTRON_IP="$(ds node-show $VMWARE_NEUTRON_NODEID|grep Address|grep -v ServiceAddress|awk '{print $4}'|cut -d'"' -f2)"
VMWARE_JOB_CREATED=false

if [ -z "$(ds job-list | grep gemini-vmware)" ];then
    #ds job-create -t "$VMWARE_REGION_TEMPLATE_ID" -P  "VMHostIP=9.115.78.69;VMHostPassword=passw0rd;VMHostUserName=root;VMServerHost=9.115.78.69;VMServerPassword=passw0rd;VMClusterName=gemini-cluster;VMServerUserName=root;VMDataCenterPath=gemini-cluster;VMDataStoreName=cloud-ds1;VMImageDataStoreName=cloud-ds1;VniRange=10000:20000;VxlanMultiCastGroup=224.0.0.200;RegionName=RegionVMware"  -N "neutron_network_node=$VMWARE_NEUTRON_NODEID;vmware_region_server=$VMWARE_REGION_NODEID" -p "$CENTRAL_JOB_ID" gemini-vmware-neutron
    ds job-create -t "$VMWARE_REGION_TEMPLATE_ID" -P  "VMServerHost=9.115.78.69;VMServerPassword=passw0rd;VMClusterName=gemini-cluster;VMServerUserName=root;VMDataCenterPath=gemini-cluster;VMDataStoreName=cloud-ds1;VMImageDataStoreName=cloud-ds1;VniRange=10000:20000;VxlanMultiCastGroup=224.0.0.200;RegionName=RegionVMware;VMInterface=vmnic1"  -N "neutron_network_node=$VMWARE_NEUTRON_NODEID;vmware_region_server=$VMWARE_REGION_NODEID" -p "$CENTRAL_JOB_ID" gemini-vmware-neutron
    #ds job-create -t "$VMWARE_REGION_TEMPLATE_ID" -P  "VMServerHost=9.115.78.69;VMServerPassword=passw0rd;VMClusterName=gemini-cluster;VMServerUserName=root;VMDataCenterPath=gemini-dc;VMDataStoreName=cloud-ds1;VMImageDataStoreName=cloud-ds1;RegionName=RegionVMware;VMInterface=vmnic1" -N "neutron_network_node=$VMWARE_NEUTRON_NODEID;vmware_region_server=$VMWARE_REGION_NODEID;vr_ico_agents_sar=c6ba8fa9-0ae6-4001-9ca5-2071f3b271a8;nn_ico_agents_sar=c20f4a45-7088-4392-b2cb-1ae874eec415" -p "$CENTRAL_JOB_ID" gemini-vmware-neutron
    if [[ $? -ne 0 || ! -z "$(ds job-list | grep gemini-vmware | grep ERROR)" ]];then
       echo "gemini-vmware-neutron job create failed!"
       cat /var/log/ds/ds-engine.log
       exit 5
    fi
    VMWARE_JOB_CREATED=true
fi
VMWARE_JOB_ID=`ds job-list | grep gemini-vmware | awk '{print $2}'`
for i in {gemini-vmware-region,gemini-vmware-neutron}; do
    ssh -o StrictHostKeyChecking=no R27-IDP-2 "virsh destroy $i; sleep 3; virsh snapshot-revert $i --current; sleep 3; virsh start $i"
done
sleep 300
for i in {gemini-vmware-region,gemini-vmware-neutron}; do
    scp -o StrictHostKeyChecking=no /etc/resolv.conf $i:/etc/resolv.conf
    ssh -o StrictHostKeyChecking=no $i 'mkdir -p /etc/chef/; modprobe vxlan'
    scp -o StrictHostKeyChecking=no /etc/chef/databag_secret $i:/etc/chef/
done
#for i in {gemini-vmware-region,gemini-vmware-neutron}; do 
#    nova stop $i
#    instance_name="$(nova show $i|grep instance_name|awk '{print $4}')" 
#    hypervisor="$(nova show $i|grep hypervisor_hostname|awk '{print $4}')"
#    sleep 5
#    ssh -o StrictHostKeyChecking=no $hypervisor "virsh snapshot-revert $instance_name --current"
#    sleep 10
#    nova start $i
#done
#sleep 400
#scp -o StrictHostKeyChecking=no  /root/sco/scripts/resolv.conf $VMWARE_REGION_IP:/etc/resolv.conf
#scp -o StrictHostKeyChecking=no  /root/sco/scripts/resolv.conf $VMWARE_NEUTRON_IP:/etc/resolv.conf
#ssh -o StrictHostKeyChecking=no $VMWARE_NEUTRON_IP 'echo "nameserver 9.0.148.50" >> /etc/resolv.conf; mkdir -p /etc/chef/'
#ssh -o StrictHostKeyChecking=no $VMWARE_NEUTRON_IP 'mkdir -p /etc/chef/'
#scp -o StrictHostKeyChecking=no  /etc/chef/databag_secret $VMWARE_NEUTRON_IP:/etc/chef/
#ssh -o StrictHostKeyChecking=no $VMWARE_REGION_IP 'echo "nameserver 9.0.148.50" >> /etc/resolv.conf; mkdir -p /etc/chef/'
#ssh -o StrictHostKeyChecking=no $VMWARE_REGION_IP 'mkdir -p /etc/chef/'
#scp -o StrictHostKeyChecking=no  /etc/chef/databag_secret $VMWARE_REGION_IP:/etc/chef/
#ds job-execute $VMWARE_JOB_ID

> /var/log/ds/ds-engine-$VMWARE_JOB_ID.log

if $VMWARE_JOB_CREATED; then
   ds job-execute $VMWARE_JOB_ID
else
   ds job-update $VMWARE_JOB_ID
fi
if [ -z "$(ds job-list | grep gemini-vmware)" ]; then
    echo "VMWare job execute failed !!"
    exit 1
fi
while true; do
    VMWARE_JOB_STATUS=$(ds job-list | grep gemini-vmware | awk '{print $6}')
    if [[ $? -ne 0 || "$VMWARE_JOB_STATUS" == "ERROR" ]]; then
        echo "VMWare region deployment failed !"
        cat /var/log/ds/ds-engine-$VMWARE_JOB_ID.log
	exit 1
    elif [[ "$VMWARE_JOB_STATUS" == "FINISHED" || "$VMWARE_JOB_STATUS" == "UPDATE_FINISHED" ]]; then
        ds job-list
        break
    fi
    sleep 300
done

#cat /var/log/ds/ds-engine-$VMWARE_JOB_ID.log
echo "======== create network and image ========================="

ssh -o StrictHostKeyChecking=no gemini-vmware-region << EOH
source /root/openrc
neutron net-create vmware-net --provider:network_type flat --provider:physical_network physnet1
neutron subnet-create vmware-net 10.10.100.0/24 --name vmware_subnet1
wget -nv http://9.181.26.252/scp22imagePre/vmware/debian-2.6.32-i686.vmdk
glance image-create --name debian-2.6.32-i686 --is-public=True --container-format=bare --disk-format=vmdk --file /root/debian-2.6.32-i686.vmdk
EOH

exit 0

