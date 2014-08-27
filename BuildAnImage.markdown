## Create a base qcow2 file
	qemu-img create -f qcow2 centos7_15g.img 15g

## Install CentOS 7 over centos7_15g.img

## Configure virtio disk
![virtio_disk](images/20140827_virtio_disk.png)

## Configure virtio network interface card
![virtio_nic](images/20140827_virtio_network_bridge.png)
