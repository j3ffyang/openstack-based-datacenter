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

if [ -z "$(ds node-list | grep gemini-kvm-region)" ];then
    ds node-create -p "{Port: 22, Password: passw0rd, User: root, Address: 9.115.78.70, Fqdn: gemini-kvm-region.gemini.cdl.ibm.com}" -t "IBM::SCO::Node" gemini-kvm-region
fi
if [ -z "$(ds node-list | grep gemini-kvm-neutron)" ];then
    ds node-create -p "{Port: 22, Password: passw0rd, User: root, Address: 9.115.78.73, Fqdn: gemini-kvm-neutron.gemini.cdl.ibm.com}" -t "IBM::SCO::Node" gemini-kvm-neutron
fi
if [ -z "$(ds node-list | grep gemini-kvm-compute-1)" ];then
    ds node-create -p "{Port: 22, Password: passw0rd, User: root, Address: 9.115.78.77, Fqdn: R27-IDP-102.gemini.cdl.ibm.com}" -t "IBM::SCO::Node" gemini-kvm-compute-1
fi
if [ -z "$(ds node-list | grep gemini-kvm-compute-2)" ];then
    ds node-create -p "{Port: 22, Password: passw0rd, User: root, Address: 9.115.78.78, Fqdn: R27-IDP-106.gemini.cdl.ibm.com}" -t "IBM::SCO::Node" gemini-kvm-compute-2
fi
if [ -z "$(ds node-list | grep gemini-kvm-compute-3)" ];then
    ds node-create -p "{Port: 22, Password: passw0rd, User: root, Address: 9.115.78.79, Fqdn: R27-IDP-109.gemini.cdl.ibm.com}" -t "IBM::SCO::Node" gemini-kvm-compute-3
fi
if [ -z "$(ds node-list | grep gemini-kvm-compute-4)" ];then
    ds node-create -p "{Port: 22, Password: passw0rd, User: root, Address: 9.115.78.81, Fqdn: R27-IDP-110.gemini.cdl.ibm.com}" -t "IBM::SCO::Node" gemini-kvm-compute-4
fi

sleep 10

KVM_REGION_TEMPLATE_ID="$(ds template-list|grep kvm_region-with-compute-neutron|grep -v HA|grep -v sharedb|awk '{print $2}')"
KVM_NEUTRON_NODEID="$(ds node-list|grep gemini-kvm-neutron|awk '{print $2}')"
KVM_NEUTRON_IP="$(ds node-show $KVM_NEUTRON_NODEID|grep Address|grep -v ServiceAddress|awk '{print $4}'|cut -d'"' -f2)"
KVM_REGION_NODEID="$(ds node-list|grep gemini-kvm-region|grep -v p1|awk '{print $2}')"
KVM_REGION_IP="$(ds node-show $KVM_REGION_NODEID|grep Address|grep -v ServiceAddress|awk '{print $4}'|cut -d'"' -f2)"
#KVM_COMPUTE_NODEID="$(ds node-list|grep gemini-kvm-compute|awk '{print $2}')"
KVM_COMPUTE=""
#node_role="kvm_compute"
for i in $(ds node-list|grep gemini-kvm-compute|awk '{print $2}'); do
    #KVM_COMPUTE="$KVM_COMPUTE$node_role=$i,"
    KVM_COMPUTE="$KVM_COMPUTE$i,"
done
KVM_COMPUTE="$(echo $KVM_COMPUTE|cut -d',' -f1-4)"

KVM_JOB_CREATED=false
if [ -z "$(ds job-list | grep gemini-kvm)" ];then
    #NEUTRON_NODE="neutron_network_node=$KVM_NEUTRON_NODEID"
    #ds job-create -t "$KVM_REGION_TEMPLATE_ID" -N "kvm_region_neutron=$KVM_REGION_NODEID;kvm_compute=$KVM_COMPUTE_NODEID;neutron_network_node=$KVM_NEUTRON_NODEID" -P "ExtNetInterface=eth1;VniRange=10000:20000;VxlanMultiCastGroup=224.0.0.200;RegionName=RegionKVM" -p "$CENTRAL_JOB_ID" gemini-kvm-neutron
    ds job-create -t "$KVM_REGION_TEMPLATE_ID" -N "kvm_region_neutron=$KVM_REGION_NODEID;kvm_compute=$KVM_COMPUTE;neutron_network_node=$KVM_NEUTRON_NODEID" -P "DataNetInterface=eth1;ExtNetInterface=eth1;MGMNetInterface=eth1;VniRange=10000:20000;VxlanMultiCastGroup=224.0.0.210;RegionName=RegionKVM" -p "$CENTRAL_JOB_ID" gemini-kvm-neutron
    #ds job-create -t "$KVM_REGION_TEMPLATE_ID" -N "kvm_region_neutron=$KVM_REGION_NODEID;kvm_compute=$KVM_COMPUTE_NODEID;neutron_network_node=$KVM_NEUTRON_NODEID;krn_ico_agents_sar=769be597-a3c6-485f-9032-96260676c56a;nnn_ico_agents_sar=6024ffc6-8b50-4e8d-8251-c0fa0f63fd0f;kc_ico_agents_sar=21e36ce6-eb87-47e6-a0c6-5b434db543c1" -P "ExtNetInterface=eth1;VniRange=10000:20000;VxlanMultiCastGroup=224.0.0.200;RegionName=RegionKVM" -p "$CENTRAL_JOB_ID" gemini-kvm-neutron
    if [[ $? -ne 0 || ! -z "$(ds job-list | grep gemini-kvm | grep ERROR)" ]];then
       echo "gemini-kvm-neutron job create failed!"
       cat /var/log/ds/ds-engine.log
       exit 3
    fi
    KVM_JOB_CREATED=true
fi
KVM_JOB_ID=`ds job-list | grep gemini-kvm | awk '{print $2}'`
ssh -o StrictHostKeyChecking=no R27-IDP-6 "virsh destroy gemini-kvm-region; sleep 3; virsh snapshot-revert gemini-kvm-region --current; sleep 3; virsh start gemini-kvm-region"

# clear neutron node
ssh -o StrictHostKeyChecking=no gemini-kvm-neutron << EON
set -x
/etc/init.d/neutron-metadata-agent stop
/etc/init.d/neutron-dhcp-agent stop
/etc/init.d/neutron-l3-agent stop
/etc/init.d/neutron-linuxbridge-agent stop
/etc/init.d/dnsmasq stop
killall -9 neutron-ns-metadata-proxy
sleep 10
ip addr add 9.115.78.73/24 dev eth1
ip route add 9.0.0.0/8 via 9.115.78.1 dev eth1
ip route change 9.0.0.0/8 via 9.115.78.1 dev eth1
ip link del vxlan-10000
EON

netns=$(ssh -o StrictHostKeyChecking=no gemini-kvm-neutron "ip netns")
for i in $netns; do $(ssh -o StrictHostKeyChecking=no gemini-kvm-neutron "ip netns delete $i"); done

brq=$(ssh -o StrictHostKeyChecking=no gemini-kvm-neutron "brctl show | grep brq | awk '{print \$1}'")
for i in $brq; do $(ssh -o StrictHostKeyChecking=no gemini-kvm-neutron "ip link set down $i; brctl delbr $i"); done

link=$(ssh -o StrictHostKeyChecking=no gemini-kvm-neutron "ip link list | grep tap | awk '{print \$2}' | cut -d':' -f1")
for i in $link; do $(ssh -o StrictHostKeyChecking=no gemini-kvm-neutron "ip link set down $i; ip link del $i"); done

sleep 300

for i in {gemini-kvm-region,gemini-kvm-neutron,R27-IDP-102,R27-IDP-106,R27-IDP-109,R27-IDP-110}; do
    scp -o StrictHostKeyChecking=no /etc/resolv.conf $i:/etc/resolv.conf
    ssh -o StrictHostKeyChecking=no $i 'mkdir -p /etc/chef/; yum clean all'
    scp -o StrictHostKeyChecking=no /etc/chef/databag_secret $i:/etc/chef/
done

> /var/log/ds/ds-engine-$KVM_JOB_ID.log

if $KVM_JOB_CREATED; then
   ds job-execute $KVM_JOB_ID
else
   ds job-update $KVM_JOB_ID
fi
if [ -z "$(ds job-list | grep gemini-kvm)" ]; then
    echo "KVM job execute failed !!"
    exit 1
fi
while true; do
    KVM_JOB_STATUS=$(ds job-list | grep gemini-kvm | awk '{print $6}')
    if [[ $? -ne 0 || "$KVM_JOB_STATUS" == "ERROR" ]]; then
        echo "KVM region deployment failed !"
        cat /var/log/ds/ds-engine-$KVM_JOB_ID.log
        exit 1	
    elif [[ "$KVM_JOB_STATUS" == "FINISHED" || "$KVM_JOB_STATUS" == "UPDATE_FINISHED" ]]; then
        ds job-list
        break
    fi
    sleep 300
done

#cat /var/log/ds/ds-engine-$KVM_JOB_ID.log
echo "======== create network and image ========================="

ssh -o StrictHostKeyChecking=no gemini-kvm-neutron << EOR
sed -i "s/local_ip = {}/local_ip = 9.115.78.73/" /etc/neutron/plugins/linuxbridge/linuxbridge_conf.ini
/etc/init.d/neutron-linuxbridge-agent restart
EOR

ssh -o StrictHostKeyChecking=no gemini-kvm-region << EOH
set -x
source /root/openrc
neutron net-create public --router:external=True --provider:network_type flat --provider:physical_network physnet1 
neutron subnet-create public 9.111.102.0/24 --name public_subnet --disable-dhcp --allocation-pool start=9.111.102.50,end=9.111.102.60 --gateway=9.111.102.1
neutron router-create router-9x
sleep 60
neutron net-create kvm-net --provider:network_type vxlan --provider:segmentation_id 10000
neutron subnet-create kvm-net 10.10.200.0/24 --dns_nameservers list=true 9.115.78.212 --name kvm_subnet1
neutron router-interface-add router-9x kvm_subnet1
neutron router-gateway-set router-9x public
wget -nv http://9.181.26.252/data/cirros.img
glance image-create --name cirros --is-public=True --container-format=bare --disk-format=qcow2 --file /root/cirros.img
EOH


exit 0

