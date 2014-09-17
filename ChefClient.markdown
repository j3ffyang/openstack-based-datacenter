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

## Bootstrap
Since all VMs/ hosts are located within a private network plus #GFW, we'd have to create our own chef-client repo. Run the following commands on Chef server
Sample files can be found at [~/samples](samples/)

	# clone git
	cd /opt/git/; git clone git@github.rtp.raleigh.ibm.com:zodiacplus/mustang.git

	# populate .ssh/* to client
	ssh -t root@172.16.0.36 "mkdir ~/.ssh"; scp ~/.ssh/id_rsa* 172.16.0.36:~/.ssh/; ssh-copy-id root@172.16.0.36

	# copy hosts
	scp /opt/git/mustang/samples/hosts/hosts 172.16.0.36:/etc/

	# populate repos
	ssh -t root@172.16.0.36 "mv /etc/yum.repos.d/CentOS*.repo /tmp/"
	scp /opt/git/mustang/samples/yum_repos_d/*.repo 172.16.0.36:/etc/yum.repos.d/

	# install wget and git
	ssh -t root@172.16.0.36 "yum install git wget -y"

	# download chef-client on client
	ssh -t root@172.16.0.36 "yum install chef -y"
