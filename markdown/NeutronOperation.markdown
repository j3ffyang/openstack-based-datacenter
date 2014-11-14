## Create network

	neutron net-create netgre-1 --tenant-id 58c0b4e7a3964e1488ac1e3d757c7df6 --provider:network_type gre --provider:segmentation_id 1000
	neutron net-create public-9x --router:external=True --provider:network_type flat --provider:physical_network physnet3
	
	neutron subnet-create netgre-1 10.100.100.0/24 --name gre-1-subnet
	neutron subnet-create public-9x 9.110.178.0/24 --name public_subnet --disable-dhcp --allocation-pool start=9.110.178.100,end=9.110.178.150 --gateway=9.110.178.1

	neutron router-create router-9x
	neutron router-interface-add router-9x netgre-1
	neutron router-gateway-set router-9x public-9x

	neutron floatingip-create public-9x

## Crete floating IP

	neutron floatingip-create public-9x
