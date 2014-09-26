## Prepare for OpenStack
	
	[root@r83x6u16 ~]# ceph osd pool create volumes 128 128
	pool 'volumes' created
	[root@r83x6u16 ~]# ceph osd pool create images 128 128
	pool 'images' created
	[root@r83x6u16 ~]# ceph osd pool set volumes size 3
	set pool 3 size to 3
	[root@r83x6u16 ~]# ceph osd pool set images size 3
	set pool 4 size to 3
	
