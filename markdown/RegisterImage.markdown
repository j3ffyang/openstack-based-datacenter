## Build an HTTP

We're going to register all image through HTTP. Therefore, we'd need to choose r83x5u08 to build an HTTP Apache server first.

	yum install httpd -y
	systemctl enable httpd.service
	systemctl start httpd.service

## Convert image into raw format which is required by Ceph

	qemu-img convert -f qcow2 -O raw centos7_15g.img centos7_15g.raw

## Place images into HTTPd

	[root@r83x5u08 images]# pwd
	/var/www/html/images
	[root@r83x5u08 images]# ls -la
	total 9840168
	drwxr-xr-x. 2 root root        4096 Nov  3 14:59 .
	drwxr-xr-x. 3 root root          19 Nov  3 14:57 ..
	-rw-r--r--. 1 root root 16106127360 Nov  3 14:45 centos7_15g.raw
	-rw-r--r--. 1 root root    41126400 Nov  3 14:59 cirros-0.3.1-raw-rbd
	-rw-r--r--. 1 root root  8984199168 Nov  3 15:00 coreos_production_openstack_image.img.raw

## Register image from glance client

	glance image-create --name centos7_15g --disk-format raw --container-format bare --is-public True --location http://172.16.0.22/images/centos7_15g.raw
