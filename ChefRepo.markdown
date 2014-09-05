## Chef Architecture
![chef arch](images/20140105_chef_arch_sl_github_io.jpg)

Credit: [http://softlayer.github.io/chef-openstack/developing-havana/](http://softlayer.github.io/chef-openstack/developing-havana/)

## Launch a VM then Install Chef
From r83x5u09,     

	cd /var/lib/libvirt/images
	cp centos7_15g.qcow2 chef.qcow2; cp centos7_15g.xml chef.xml    

Modify xml definition to reflect template name, VM name and disk name, then    

	virsh create chef.xml
