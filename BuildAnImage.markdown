## Create a base qcow2 file
	qemu-img create -f qcow2 centos7_15g.img 15g

## Install CentOS 7 over centos7_15g.img

## Configure virtio disk
![virtio_disk](images/20140827_virtio_disk.png)

## Configure virtio network interface card with bridge
![virtio_nic](images/20140827_virtio_network_bridge.png)

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
Then append "console=ttyS0"" and change "GRUB_CMDLINE_LINUX" line to
	GRUB_CMDLINE_LINUX="rd.lvm.lv=centos/swap vconsole.font=latarcyrheb-sun16 rd.lvm.lv=centos/root crashkernel=auto  vconsole.keymap=us rhgb quiet console=ttyS0"

Update grub
	grub2-mkconfig -o /boot/grub2/grub.cfg
