#!/bin/bash
set -x 

CURRENT_BUILD=`cat /opt/ibm/cloud-deployer/ico.version | grep build_number | awk '{print $2}' | tr -d '"'`
echo "The ICO build version is: $CURRENT_BUILD"

source /root/keystonerc 

> /var/log/ds/ds-engine.log

#CENTRAL_JOB_ID=`ds job-list | grep gemini-central | awk '{print $2}'`
#KVM_JOB_ID=`ds job-list | grep gemini-kvm | awk '{print $2}'`
#VMWARE_JOB_ID=`ds job-list | grep gemini-vmware | awk '{print $2}'`
JOB_FAILED=0
if [ -z "$(ds node-list | grep gemini-central-1)" ];then
    ds node-create -p "{Port: 22, Password: passw0rd, User: root, Address: 9.115.78.83, Fqdn: gemini-central-1.gemini.cdl.ibm.com}" -t "IBM::SCO::Node" gemini-central-1
fi
if [ -z "$(ds node-list | grep gemini-central-2)" ];then
    ds node-create -p "{Port: 22, Password: passw0rd, User: root, Address: 9.115.78.84, Fqdn: gemini-central-2.gemini.cdl.ibm.com}" -t "IBM::SCO::Node" gemini-central-2
fi
if [ -z "$(ds node-list | grep gemini-central-3)" ];then
    ds node-create -p "{Port: 22, Password: passw0rd, User: root, Address: 9.115.78.87, Fqdn: gemini-central-3.gemini.cdl.ibm.com}" -t "IBM::SCO::Node" gemini-central-3
fi

sleep 10

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
    #ds job-create -t "$CENTRAL_SERVERS_TEMPLATE_ID" -N "central_server_1=$CENTRAL_SERVER_1_NODEID;central_server_2=$CENTRAL_SERVER_2_NODEID;central_server_3=$CENTRAL_SERVER_3_NODEID;cs1_ico_agents_all_1=62a2d954-c68a-44df-b18d-13f57344e1df;cs2_ico_agent_sar=904a1021-f3d8-42a9-b32e-cf42548ad1a2;cs3_ico_agent_sar=ddb5bbcf-e8b9-4874-a8e9-34c2700df8d4" -P "RegionName=RegionKVM" gemini-central-servers
    if [[ $? -ne 0 || ! -z "$(ds job-list | grep gemini-central | grep ERROR)" ]];then
       echo "gemini-central-servers job create failed!"
       cat /var/log/ds/ds-engine.log
       $JOB_FAILED=1
       exit 1 
    fi
    CENTRAL_JOB_CREATED=true
fi
CENTRAL_JOB_ID=`ds job-list | grep gemini-central | awk '{print $2}'`
for i in {gemini-central-1,gemini-central-2,gemini-central-3}; do
    ssh -o StrictHostKeyChecking=no R27-IDP-6 "virsh destroy $i; sleep 3; virsh snapshot-revert $i --current; sleep 3; virsh start $i"
done
sleep 300
for i in {gemini-central-1,gemini-central-2,gemini-central-3}; do
    scp -o StrictHostKeyChecking=no /etc/resolv.conf $i:/etc/resolv.conf
    ssh -o StrictHostKeyChecking=no $i 'mkdir -p /etc/chef/'
    scp -o StrictHostKeyChecking=no /etc/chef/databag_secret $i:/etc/chef/
done

#scp -o StrictHostKeyChecking=no  /root/sco/scripts/resolv.conf $CENTRAL_SERVER_1_IP:/etc/resolv.conf
#scp -o StrictHostKeyChecking=no  /root/sco/scripts/resolv.conf $CENTRAL_SERVER_2_IP:/etc/resolv.conf
#scp -o StrictHostKeyChecking=no  /root/sco/scripts/resolv.conf $CENTRAL_SERVER_3_IP:/etc/resolv.conf
#ssh -o StrictHostKeyChecking=no $CENTRAL_SERVER_1_IP 'echo "nameserver 9.0.148.50" >> /etc/resolv.conf; mkdir -p /etc/chef/'
#ssh -o StrictHostKeyChecking=no $CENTRAL_SERVER_1_IP 'mkdir -p /etc/chef/'
#scp -o StrictHostKeyChecking=no  /etc/chef/databag_secret $CENTRAL_SERVER_1_IP:/etc/chef/
#scp -o StrictHostKeyChecking=no  /root/sco/scripts/hosts $CENTRAL_SERVER_1_IP:/etc/hosts
#ssh -o StrictHostKeyChecking=no $CENTRAL_SERVER_2_IP 'echo "nameserver 9.0.148.50" >> /etc/resolv.conf; mkdir -p /etc/chef/'
#ssh -o StrictHostKeyChecking=no $CENTRAL_SERVER_2_IP 'mkdir -p /etc/chef/'
#scp -o StrictHostKeyChecking=no  /etc/chef/databag_secret $CENTRAL_SERVER_2_IP:/etc/chef/
#scp -o StrictHostKeyChecking=no  /root/sco/scripts/hosts $CENTRAL_SERVER_1_IP:/etc/hosts
#ssh -o StrictHostKeyChecking=no $CENTRAL_SERVER_3_IP 'echo "nameserver 9.0.148.50" >> /etc/resolv.conf; mkdir -p /etc/chef/'
#ssh -o StrictHostKeyChecking=no $CENTRAL_SERVER_3_IP 'mkdir -p /etc/chef/'
#scp -o StrictHostKeyChecking=no  /etc/chef/databag_secret $CENTRAL_SERVER_3_IP:/etc/chef/
#scp -o StrictHostKeyChecking=no  /root/sco/scripts/hosts $CENTRAL_SERVER_1_IP:/etc/hosts

> /var/log/ds/ds-engine-$CENTRAL_JOB_ID.log

if $CENTRAL_JOB_CREATED; then
   ds job-execute $CENTRAL_JOB_ID
else
   ds job-update $CENTRAL_JOB_ID
fi
if [ -z "$(ds job-list | grep gemini-central)" ]; then
    echo "Central servers job execute failed !!"
    exit 1
fi
while true; do
    CENTRAL_JOB_STATUS=$(ds job-list | grep gemini-central | awk '{print $6}')
    if [[ $? -ne 0 || "$CENTRAL_JOB_STATUS" == "ERROR" ]]; then
	echo "Central servers deployment failed !"
        cat /var/log/ds/ds-engine-$CENTRAL_JOB_ID.log
	exit 1
    elif [[ "$CENTRAL_JOB_STATUS" == "FINISHED" || "$CENTRAL_JOB_STATUS" == "UPDATE_FINISHED" ]]; then
        ds job-list
        break
    fi
    sleep 300
done

#cat /var/log/ds/ds-engine-$CENTRAL_JOB_ID.log

exit 0

