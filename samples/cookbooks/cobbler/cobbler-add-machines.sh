#!/bin/bash
#set -x

ASU_HOME="/iaas/gemini/asu"

add_machine() {
	IMM_ADDR=$1
	IMM_USER="USERID"
	IMM_PWD="PASSW0RD"

	imm_info=`$ASU_HOME/asu64 show all --host $IMM_ADDR --USER $IMM_USER --password $IMM_PWD | grep "PXE.NicPortMacAddress.1\|IMM.HostName1"`
	mac=`echo $imm_info | cut -d' ' -f2 | cut -d'=' -f2`
	name=`echo $imm_info | cut -d' ' -f1 | cut -d'=' -f2`
	#mac=`$ASU_HOME/asu64 show PXE.NicPortMacAddress.1 --host $IMM_ADDR --USER $IMM_USER --password $IMM_PWD | grep PXE.NicPortMacAddress.1 | cut -d'=' -f'2'`
        #name=`$ASU_HOME/asu64 show IMM.HostName1 --host $IMM_ADDR --USER $IMM_USER --password $IMM_PWD | grep IMM.HostName1 | cut -d'=' -f'2'`
	rack_id=`echo $name |cut -d'-' -f1`
	rack_no=`echo ${rack_id:1:2}`
	unit_no=`echo $name |cut -d'-' -f3`

        #if [[-z  "${mac}"] || [-z "${name}"]] ; then
        if [[ (${#mac} -eq 0) || (${#name} -eq 0) ]] ; then
                echo "ASU query failed for $IMM_ADDR !!"
        else
                echo "$name $IMM_ADDR ${mac//-/:}"
		$ASU_HOME/asu64 set BootOrder.BootOrder "PXE Network=CD/DVD Rom=Hard Disk 0=Legacy Only" --host $IMM_ADDR --user $IMM_USER --password $IMM_PWD
		$ASU_HOME/asu64 set PXE.NicPortPxeMode.1 "Legacy Support" --host $IMM_ADDR --user $IMM_USER --password $IMM_PWD
		$ASU_HOME/asu64 set PXE.NicPortPxeMode.2 Disabled --host $IMM_ADDR --user $IMM_USER --password $IMM_PWD
		cobbler system add --name=$name --profile=RHEL65-x86_64 --interface=eth0 --mac= ${mac//-/:} --ip-address=172.16.$rack_no.$unit_no --netmask=255.255.255.0 --gateway=172.16.$rack_no.1 --hostname=$name --power-type=imm --power-address=$IMM_ADDR --power-user=$IMM_USER --power-pass=$IMM_PWD --server=172.16.27.199 --kickstar=/var/lib/cobbler/kickstarts/gemini-phy-raw.ks
                #MACHINE_MACS+="${mac//-/:} "
                #MACHINE_POWERADDRESS+="$IMM_ADDR "
                #MACHINE_POWERUSER+="$IMM_USER "
                #MACHINE_POWERPASS+="$IMM_PWD "
                #MACHINE_POWERTYPES+="ipmitool "
        fi
}

#cat gemini-imm.lst | while read LINE; do
while read LINE; do
	add_machine $LINE
done < gemini-imm.lst
cobbler sync
