## Chef Architecture
![chef arch](images/20140105_chef_arch_sl_github_io.jpg)

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

## Install and Configure Chef-Client    
Download    

	wget https://opscode-omnibus-packages.s3.amazonaws.com/el/6/x86_64/chef-11.16.0-1.el6.x86_64.rpm

or directly install from web    

	curl -L https://www.opscode.com/chef/install.sh | bash

Configure chef-client on chef-server

	[root@chef ~]# mkdir .chef
	[root@chef ~]# scp /etc/chef-server/
	admin.pem                 chef-server-secrets.json  chef-webui.pem            
	chef-server-running.json  chef-validator.pem        
	[root@chef ~]# scp /etc/chef-server/admin.pem ~/.chef/
	[root@chef ~]# scp /etc/chef-server/chef-
	chef-server-running.json  chef-server-secrets.json  chef-validator.pem        chef-webui.pem
	[root@chef ~]# scp /etc/chef-server/chef-validator.pem ~/.chef/
	[root@chef ~]# knife configure -i
	WARNING: No knife configuration file found
	Where should I put the config file? [/root/.chef/knife.rb] 
	Please enter the chef server URL: [https://chef:443] 
	Please enter a name for the new user: [root] 
	Please enter the existing admin name: [admin] 
	Please enter the location of the existing admin's private key: [/etc/chef-server/admin.pem] 
	Please enter the validation clientname: [chef-validator] 
	Please enter the location of the validation key: [/etc/chef-server/chef-validator.pem] 
	Please enter the path to a chef repository (or leave blank): 
	Creating initial API user...
	Please enter a password for the new user: 
	Created user[root]
	Configuration file written to /root/.chef/knife.rb

## Boostrap
Since all VMs/ hosts are located within a private network plus #GFW, we'd have to create our own chef-client repo. Run the following commands on Chef server

	# clone git
	cd /opt/git/; git clone git@github.rtp.raleigh.ibm.com:zodiacplus/mustang.git

	# populate .ssh/* to client
	ssh -t root@172.16.0.36 "mkdir ~/.ssh"; scp ~/.ssh/id_rsa* 172.16.0.36:~/.ssh/; ssh-copy-id root@172.16.0.36

	# copy hosts
	scp /opt/git/mustang/samples/hosts/hosts 172.16.0.36:/etc/

	# populate repos
	scp /opt/git/mustang/samples/yum_repos_d/*.repo 172.16.0.36:/etc/yum.repos.d/
