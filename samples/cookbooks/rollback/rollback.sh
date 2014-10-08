#!/bin/bash

DS_ID=`virsh list | grep rhel65-demo-ds | awk '{print $1}'`
virsh  destroy ${DS_ID}
cp -f /var/build_vms/${GBUILD}/rhel65-demo-ds.img /var/
virsh start rhel65-demo-ds

DATE=`date +%s`
while (($[`date +%s` - ${DATE}]<180))
  do
    echo "wait for demo ds startup."
    ping 9.115.78.75 -c 2
    if [ $? -eq 0 ];then
        break
    fi
 sleep 5
done
