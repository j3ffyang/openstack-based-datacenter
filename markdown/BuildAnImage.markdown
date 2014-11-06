## Create a base qcow2 file
	qemu-img create -f qcow2 centos7_15g.img 15g

## Install CentOS 7 over centos7_15g.img

## Configure virtio disk
![virtio_disk](images/20140827_virtio_disk.png)

## Configure virtio network interface card with bridge
![virtio_nic](images/20140827_virtio_network_bridge.png)

## Convert a qcow2 image as base image
	qemu-img create -b centos7_15g.img -o cluster_size=2M -f qcow2 centos7_15g.qcow2

## Modify disk format in xml as base xml definition [sample xml](samples/vm_xml/centos7_15g.xml)
	...
	<disk type='file' device='disk'>
	  <driver name='qemu' type='qcow2' cache='none'/>
	  <source file='/var/lib/libvirt/images/centos7_15g.qcow2'/>
	  <target dev='vda' bus='virtio'/>
	  <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
    	</disk>
	...

## Disable SELinux
	[root@localhost ~]# cat /etc/selinux/config

	# This file controls the state of SELinux on the system.
	# SELINUX= can take one of these three values:
	#     enforcing - SELinux security policy is enforced.
	#     permissive - SELinux prints warnings instead of enforcing.
	#     disabled - No SELinux policy is loaded.
	SELINUX=disabled
	# SELINUXTYPE= can take one of these two values:
	#     targeted - Targeted processes are protected,
	#     mls - Multi Level Security protection.
	SELINUXTYPE=targeted

## Change console to display in command line
	vi /etc/default/grub
Then append "console=ttyS0" and change "GRUB_CMDLINE_LINUX" line to   

	GRUB_CMDLINE_LINUX="rd.lvm.lv=centos/swap vconsole.font=latarcyrheb-sun16 rd.lvm.lv=centos/root crashkernel=auto  vconsole.keymap=us rhgb quiet console=ttyS0"

Update grub   

	grub2-mkconfig -o /boot/grub2/grub.cfg

## Create repo as [CreateCentosRepo](CreateCentosRepo.markdown)

## Add proxy when VM residing within private network     
	export http_proxy=http://9.115.78.100:8085/
	export https_proxy=http://9.115.78.100:8085/

## [Sample of VM XML](samples/vm_xml/)

## [/etc/host](samples/hosts/hosts) accoding to [IP Planning](IPPlanning.markdown)
