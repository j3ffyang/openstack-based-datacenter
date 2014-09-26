## Prepare for OpenStack
	
	[root@r83x6u16 ~]# ceph osd pool create volumes 128 128
	pool 'volumes' created
	[root@r83x6u16 ~]# ceph osd pool create images 128 128
	pool 'images' created
	[root@r83x6u16 ~]# ceph osd pool set volumes size 3
	set pool 3 size to 3
	[root@r83x6u16 ~]# ceph osd pool set images size 3
	set pool 4 size to 3
	
	[root@r83x6u16 ~]# ceph auth get-or-create client.cinder mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rx pool=images'
[client.cinder]
        key = AQD0ZCVUMOS6EhAAAqswAN263yDJkJmegRf6rw==
[root@r83x6u16 ~]# ceph auth get-or-create client.glance mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images'
[client.glance]
        key = AQD+ZCVUSIgDLBAA4tFE6GozDXExqc8BtDanFQ==

