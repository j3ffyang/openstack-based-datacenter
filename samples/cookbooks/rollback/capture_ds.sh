#!/bin/bash

mkdir /var/build_vms/${GBUILD}
if [ $? -eq 0 ];then
  DS_ID=`virsh list  | grep rhel65-demo-ds | awk '{print $1}'`
  virsh suspend ${DS_ID}
  cp -f /var/rhel65-demo-ds.img /var/build_vms/${GBUILD}/
  virsh resume rhel65-demo-ds
fi
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

