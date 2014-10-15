## Launch a VM

## Setup Hostname

	hostnamectl set-hostname neutron

## Assign IP Addresses, accouding to [IP Planning](IPPlanning.markdown)

## Update cookbook environment

## Trigger cookbook
Switch and log into Chef server

	knife bootstrap 172.16.0.38 -c /etc/chef/knife.rb -u root -P passw0rd -N neutron --template-file /opt/git/mustang/samples/cookbooks/erb/gemini.erb -r 'role[gemini-network]' -E gemini
