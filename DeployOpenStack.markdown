## Deploying OpenStack is done with previous steps

## Create Image

	glance --debug image-create --name cirros-0.3.1-raw-rbd --disk-format raw --container-format bare --is-public True < ~/cirros-0.3.1-raw-rbd

## Create libvirt key for Nove

	virsh secret-define --file /etc/ceph/libvirt-key.xml
	virsh secret-get-value dea66dcd-d661-4569-983a-b4a6e6f36824

## Create Network

	neutron net-create netgre-1 --tenant-id 58c0b4e7a3964e1488ac1e3d757c7df6 --provider:network_type gre --provider:segmentation_id 1000
	neutron subnet-create netgre-1 10.100.100.0/24 --name gre-1-subnet
