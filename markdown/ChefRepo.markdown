## Chef Architecture
![chef arch](/images/20140105_chef_arch_sl_github_io.jpg)

Credit: [http://softlayer.github.io/chef-openstack/developing-havana/](http://softlayer.github.io/chef-openstack/developing-havana/)

## ~~Launch a VM~~
From r83x5u09,     

	cd /var/lib/libvirt/images
	cp centos7_15g.qcow2 chef.qcow2; cp centos7_15g.xml chef.xml    

Modify xml definition to reflect template name, VM name and disk name, then    

	virsh create chef.xml

## ~~Set hostname~~
	hostnamectl set-hostname chef

## ~~Assign IP address according to [IP Planning](IPPlanning.markdown)~~
	nmtui

## ~~ifcfg-eth0 Sample~~
	[root@chef network-scripts]# pwd
	/etc/sysconfig/network-scripts
	[root@chef network-scripts]# cat ifcfg-eth0 
	HWADDR=52:54:00:D7:49:D6
	TYPE=Ethernet
	BOOTPROTO=none
	IPADDR0=172.16.0.32
	PREFIX0=16
	GATEWAY0=172.16.0.21
	DNS1=9.0.146.50
	DNS2=9.0.148.50
	DEFROUTE=yes
	IPV4_FAILURE_FATAL=no
	IPV6INIT=no
	NAME=eth0
	UUID=437b14d4-38cb-40ef-9553-5df02df114ea
	ONBOOT=yes

## ~~Install Chef~~
	wget https://opscode-omnibus-packages.s3.amazonaws.com/el/6/x86_64/chef-server-11.1.3-1.el6.x86_64.rpm 
	yum install chef-server-11.1.3-1.el6.x86_64.rpm rubygems    

Scratch all the above about CentOS 7 as Chef server doesn't support it up to this document being written

## Update Hostname and Assign IP Address according to [IP Planning](IPPlanning.markdown)

	[root@chef ~]# cd /etc/sysconfig/network-scripts/
	[root@chef network-scripts]# pwd
	/etc/sysconfig/network-scripts
	[root@chef network-scripts]# cat ifcfg-eth0 
	DEVICE=eth0
	TYPE=Ethernet
	ONBOOT=yes
	NM_CONTROLLED=no
	BOOTPROTO=none
	IPADDR=172.16.0.32
	NETMASK=255.255.0.0
	GATEWAY=172.16.0.21

## Setup yum.repos.d for CentOS 6.5

## Update /etc/hosts and Hostname     

	127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
	::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
	172.16.0.32     chef

## Install rpms
	yum install chef-server-11.1.3-1.el6.x86_64.rpm rubygems


## Start Configuration    
	chef-server-ctl reconfigure    

If the task doesn't finish successfully because of hostname not able to be resolved, just disable /etc/resolv.conf
Login as "admin"
