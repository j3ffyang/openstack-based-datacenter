Neutron server has been implemented in ctrlr0/1/2 3 boxes. Neutron VM provides agent service, including L3, DHCP, and Open vSwitch

## Architecture 
![neutron network](images/20141015_neutron_net.png)

## Launch a VM

## Setup Hostname

	hostnamectl set-hostname neutron

## Assign IP Addresses, accouding to [IP Planning](IPPlanning.markdown)

## Update /etc/hosts then Populate to All Endpoints
Edit samples/hosts/hosts

## Update cookbook environment

## Trigger cookbook
Switch and log into Chef server

	knife bootstrap 172.16.0.38 -c /etc/chef/knife.rb -u root -P passw0rd -N neutron --template-file /opt/git/mustang/samples/cookbooks/erb/gemini.erb -r 'role[gemini-network]' -E gemini

## Update sysctl.conf

	net.ipv4.ip_forward=1
	net.ipv4.conf.all.rp_filter=0
	net.ipv4.conf.default.rp_filter=0
