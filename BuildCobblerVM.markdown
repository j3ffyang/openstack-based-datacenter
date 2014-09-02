## Launch a CentOS 7 VM

## Configure network according [IP Planning](IPPlanning.markdown)
Configuration details    

	[root@localhost network-scripts]# pwd
	/etc/sysconfig/network-scripts

	[root@localhost network-scripts]# cat ifcfg-eth0
	TYPE=Ethernet
	BOOTPROTO=none
	IPADDR0=172.16.0.31
	PREFIX0=16
	DEFROUTE=yes
	IPV4_FAILURE_FATAL=no
	IPV6INIT=no
	NAME=eth0
	UUID=f4795324-fa7f-4475-8d03-c11d572a83d4
	DEVICE=eth0
	ONBOOT=yes

	[root@localhost network-scripts]# cat ifcfg-eth1
	TYPE=Ethernet
	BOOTPROTO=none
	IPADDR0=172.29.0.31
	PREFIX0=16
	DEFROUTE=yes
	IPV4_FAILURE_FATAL=no
	IPV6INIT=no
	NAME=eth1
	UUID=2533e32f-5237-45d5-abc8-b549fa1fa6e7
	DEVICE=eth1
	ONBOOT=yes

## Set hostname
	hostnamectl set-hostname cobbler

## Install Cobbler and Pre- req
	yum install cobbler cobbler-web -y
	yum install syslinux

## Edit /etc/cobbler/settings
	next_server: 172.16.0.31

## Verify /etc/httpd/conf.d/cobbler_web.conf and /etc/cobbler/modules.conf    
Most configurations are default without change in version 2.6.5

## Update the Login Credential
	htdigest /etc/cobbler/users.digest "Cobbler" cobbler

## Start Cobbler and HTTPd services
	systemctl start cobbler.service
	systemctl enable cobbler.service
	systemctl start httpd.service
	systemctl enable httpd.service

## Sync
	cobbler sync

## Import Image    
Transfer an ISO image to /mnt    
	mount -o loop CentOS-7.0-1406-x86_64-DVD.iso /mnt/centos7_mount/
	cobbler import --name=centos7 --path=/mnt/centos7_mount/ --arch=x86_64

## Create a Profile
	cobbler profile add --distro=centos65-x86_64 --name=centos65-x86_64 --kickstart=/var/lib/cobbler/kickstarts/default.ks
