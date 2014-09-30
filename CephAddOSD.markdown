## Prepare Node
Take a reference at [Ceph documentation](http://ceph.com/docs/v0.67.9/rados/operations/add-or-rm-osds/) or similar

Configure public (10.0/16) and Ceph cluster (10.10/16) network
Update hostname    
Update /etc/hosts    
Update /etc/yum.repos.d    
[Partition](CephPartition.markdown)

## Install Ceph
	
	yum install ceph

## Update [/etc/ceph/ceph.conf](samples/ceph/ceph.conf)
Update ceph.conf to add osd blocks. Then upload the change to Chef
Log into Chef

	cd /opt/git/mustang/; git pull
	scp samples/ceph/ceph.conf root@172.16.0.203:/etc/ceph/

## Copy ceph.client.admin.keyring from earlier setup Ceph node
Log in r83x6u16 (172.16.0.201). Copy /etc/ceph/ceph.client.admin.keyring to newest Ceph node

	scp 172.16.0.201:/etc/ceph/ceph.client.admin.keyring 172.16.0.203:/etc/ceph/

## Create OSD
	
	[root@localhost ceph]# ceph osd create
	3
	
	[root@localhost ceph]# mkdir -p /var/lib/ceph/osd/ceph-3
	
	[root@localhost ceph]# mkfs -t xfs -i size=2048 -f /dev/sdb2
	meta-data=/dev/sdb2              isize=2048   agcount=4, agsize=72509648 blks
	         =                       sectsz=512   attr=2, projid32bit=1
	         =                       crc=0

	data     =                       bsize=4096   blocks=290038589, imaxpct=5
	         =                       sunit=0      swidth=0 blks
	naming   =version 2              bsize=4096   ascii-ci=0 ftype=0
	log      =internal log           bsize=4096   blocks=141620, version=2
	         =                       sectsz=512   sunit=0 blks, lazy-count=1
	realtime =none                   extsz=4096   blocks=0, rtextents=0
	[root@localhost ceph]# mount -t xfs /dev/sdb2 /var/lib/ceph/osd/ceph-3
	
	[root@localhost ceph]# ceph-osd -i 3 --mkfs --mkkey
	SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0b 00 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	2014-09-19 00:19:39.438730 7f5c07c7c7c0 -1 journal read_header error decoding journal header
	SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0b 00 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0b 00 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0b 00 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	2014-09-19 00:19:39.549613 7f5c07c7c7c0 -1 filestore(/var/lib/ceph/osd/ceph-3) could not find 23c2fcde/osd_superblock/0//-1 in index: (2) No such file or directory
	2014-09-19 00:19:39.734540 7f5c07c7c7c0 -1 created object store /var/lib/ceph/osd/ceph-3 journal /dev/sdb1 for osd.3 fsid ed095412-5171-4d91-8d7e-5f5678985cd2
	2014-09-19 00:19:39.734635 7f5c07c7c7c0 -1 auth: error reading file: /var/lib/ceph/osd/ceph-3/keyring: can't open /var/lib/ceph/osd/ceph-3/keyring: (2) No such file or directory
	2014-09-19 00:19:39.734752 7f5c07c7c7c0 -1 created new key in keyring /var/lib/ceph/osd/ceph-3/keyring

	[root@localhost ceph]# ceph auth add osd.3 osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/ceph-3/keyring
	added key for osd.3
	
	[root@localhost ceph]# ceph osd crush add-bucket r83x6u18 host
	added bucket r83x6u18 type host to crush map
	
	[root@localhost ceph]# ceph osd crush move r83x6u18 root=default
	moved item id -3 name 'r83x6u18' to location {root=default} in crush map
	
	[root@localhost ceph]# ceph osd crush add osd.3 1.08 host=r83x6u18
	add item id 3 name 'osd.3' weight 1.08 at location {host=r83x6u18} to crush map
	[root@localhost ceph]# /etc/init.d/ceph start osd.3
	=== osd.3 === 
	create-or-move updated item name 'osd.3' weight 1.08 at location {host=r83x6u18,root=default} to crush map
	Starting Ceph osd.3 on r83x6u18...
	Running as unit run-8099.service.
	
	ot@localhost ceph]# ceph osd ls
	0
	1
	2
	3
	[root@localhost ceph]# ceph -s
	    cluster ed095412-5171-4d91-8d7e-5f5678985cd2
	     health HEALTH_OK
	     monmap e1: 1 mons at {r83x6u16=10.0.0.201:6789/0}, election epoch 2, quorum 0 r83x6u16
	     osdmap e23: 4 osds: 4 up, 4 in
	      pgmap v48: 192 pgs, 3 pools, 0 bytes data, 0 objects
	            139 MB used, 4423 GB / 4423 GB avail
	                 192 active+clean
	
Add the 5th OSD

	[root@localhost ceph]# ceph osd create
	4
	[root@localhost ceph]# mkdir -p /var/lib/ceph/osd/ceph-4
	[root@localhost ceph]# mkfs -t xfs -i size=2048 -f /dev/sdc2
	meta-data=/dev/sdc2              isize=2048   agcount=4, agsize=72509648 blks
	         =                       sectsz=512   attr=2, projid32bit=1
	         =                       crc=0
	data     =                       bsize=4096   blocks=290038589, imaxpct=5
	         =                       sunit=0      swidth=0 blks
	naming   =version 2              bsize=4096   ascii-ci=0 ftype=0
	log      =internal log           bsize=4096   blocks=141620, version=2
	         =                       sectsz=512   sunit=0 blks, lazy-count=1
	realtime =none                   extsz=4096   blocks=0, rtextents=0
	[root@localhost ceph]# mount -t xfs /dev/sdc2 /var/lib/ceph/osd/ceph-4
	[root@localhost ceph]# ceph-osd -i 4 --mkfs --mkkey
	SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0b 00 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	2014-09-19 00:30:19.803125 7f272bb4f7c0 -1 journal check: ondisk fsid 00000000-0000-0000-0000-000000000000 doesn't match expected b1ffef18-d90a-40a7-bd5f-5add33c1ea92, invalid (someone else's?) journal
	SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0b 00 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0b 00 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0b 00 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	2014-09-19 00:30:19.920969 7f272bb4f7c0 -1 filestore(/var/lib/ceph/osd/ceph-4) could not find 23c2fcde/osd_superblock/0//-1 in index: (2) No such file or directory
	2014-09-19 00:30:20.111104 7f272bb4f7c0 -1 created object store /var/lib/ceph/osd/ceph-4 journal /dev/sdc1 for osd.4 fsid ed095412-5171-4d91-8d7e-5f5678985cd2
	2014-09-19 00:30:20.111155 7f272bb4f7c0 -1 auth: error reading file: /var/lib/ceph/osd/ceph-4/keyring: can't open /var/lib/ceph/osd/ceph-4/keyring: (2) No such file or directory
	2014-09-19 00:30:20.111284 7f272bb4f7c0 -1 created new key in keyring /var/lib/ceph/osd/ceph-4/keyring
	[root@localhost ceph]# ceph osd crush add osd.4 1.08 host=r83x6u18
	add item id 4 name 'osd.4' weight 1.08 at location {host=r83x6u18} to crush map
	
## Add the 3rd node for reference
The following is completely copied from what I created the 3rd Ceph and join the existing Ceph cluster

	[root@r83x6u20 ceph]# mkdir -p /var/lib/ceph/osd/ceph-6
	[root@r83x6u20 ceph]# mkdir -p /var/lib/ceph/osd/ceph-7
	[root@r83x6u20 ceph]# mkdir -p /var/lib/ceph/osd/ceph-8
	
	[root@r83x6u20 ceph]# mkfs -t xfs -i size=2048 -f /dev/sdb2
	meta-data=/dev/sdb2              isize=2048   agcount=4, agsize=72509648 blks
	         =                       sectsz=512   attr=2, projid32bit=1
	         =                       crc=0
	data     =                       bsize=4096   blocks=290038589, imaxpct=5
	         =                       sunit=0      swidth=0 blks
	naming   =version 2              bsize=4096   ascii-ci=0 ftype=0
	log      =internal log           bsize=4096   blocks=141620, version=2
	         =                       sectsz=512   sunit=0 blks, lazy-count=1
	realtime =none                   extsz=4096   blocks=0, rtextents=0
	
	[root@r83x6u20 ceph]# mkfs -t xfs -i size=2048 -f /dev/sdc2
	meta-data=/dev/sdc2              isize=2048   agcount=4, agsize=72509648 blks
	         =                       sectsz=512   attr=2, projid32bit=1
	         =                       crc=0
	data     =                       bsize=4096   blocks=290038589, imaxpct=5
	         =                       sunit=0      swidth=0 blks
	naming   =version 2              bsize=4096   ascii-ci=0 ftype=0
	log      =internal log           bsize=4096   blocks=141620, version=2
	         =                       sectsz=512   sunit=0 blks, lazy-count=1
	realtime =none                   extsz=4096   blocks=0, rtextents=0
	
	[root@r83x6u20 ceph]# mkfs -t xfs -i size=2048 -f /dev/sdd2
	meta-data=/dev/sdd2              isize=2048   agcount=4, agsize=72509648 blks
	         =                       sectsz=512   attr=2, projid32bit=1
	         =                       crc=0
	data     =                       bsize=4096   blocks=290038589, imaxpct=5
	         =                       sunit=0      swidth=0 blks
	naming   =version 2              bsize=4096   ascii-ci=0 ftype=0
	log      =internal log           bsize=4096   blocks=141620, version=2
	         =                       sectsz=512   sunit=0 blks, lazy-count=1
	realtime =none                   extsz=4096   blocks=0, rtextents=0
	
	[root@r83x6u20 ceph]# mount -t xfs /dev/sdb2 /var/lib/ceph/osd/ceph-6
	[root@r83x6u20 ceph]# mount -t xfs /dev/sdc2 /var/lib/ceph/osd/ceph-7
	[root@r83x6u20 ceph]# mount -t xfs /dev/sdd2 /var/lib/ceph/osd/ceph-8
	
	
	[root@r83x6u20 ceph]# ceph-osd -i 6 --mkfs --mkkey
	SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0b 00 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	2014-09-24 22:00:45.791757 7f348c6897c0 -1 journal check: ondisk fsid 00000000-0000-0000-0000-000000000000 doesn't match expected cc04cbd7-8762-4347-b1bb-b00fa2dfc90c, invalid (someone else's?) journal
	SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0b 00 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0b 00 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0b 00 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	2014-09-24 22:00:45.809205 7f348c6897c0 -1 filestore(/var/lib/ceph/osd/ceph-6) could not find 23c2fcde/osd_superblock/0//-1 in index: (2) No such file or directory
	2014-09-24 22:00:45.844075 7f348c6897c0 -1 created object store /var/lib/ceph/osd/ceph-6 journal /dev/sdb1 for osd.6 fsid ed095412-5171-4d91-8d7e-5f5678985cd2
	2014-09-24 22:00:45.844162 7f348c6897c0 -1 auth: error reading file: /var/lib/ceph/osd/ceph-6/keyring: can't open /var/lib/ceph/osd/ceph-6/keyring: (2) No such file or directory
	2014-09-24 22:00:45.844281 7f348c6897c0 -1 created new key in keyring /var/lib/ceph/osd/ceph-6/keyring
	[root@r83x6u20 ceph]# ceph-osd -i 7 --mkfs --mkkey
	SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0b 00 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	2014-09-24 22:01:05.863954 7fb5f672f7c0 -1 journal check: ondisk fsid 00000000-0000-0000-0000-000000000000 doesn't match expected 5b1e0427-f2eb-4922-bd82-8c28f8c8bd08, invalid (someone else's?) journal
	SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0b 00 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0b 00 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0b 00 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	2014-09-24 22:01:05.883191 7fb5f672f7c0 -1 filestore(/var/lib/ceph/osd/ceph-7) could not find 23c2fcde/osd_superblock/0//-1 in index: (2) No such file or directory
	2014-09-24 22:01:05.897599 7fb5f672f7c0 -1 created object store /var/lib/ceph/osd/ceph-7 journal /dev/sdc1 for osd.7 fsid ed095412-5171-4d91-8d7e-5f5678985cd2
	2014-09-24 22:01:05.897669 7fb5f672f7c0 -1 auth: error reading file: /var/lib/ceph/osd/ceph-7/keyring: can't open /var/lib/ceph/osd/ceph-7/keyring: (2) No such file or directory
	2014-09-24 22:01:05.897785 7fb5f672f7c0 -1 created new key in keyring /var/lib/ceph/osd/ceph-7/keyring
	[root@r83x6u20 ceph]# ceph-osd -i 8 --mkfs --mkkey
	SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0b 00 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	2014-09-24 22:01:09.518975 7f0b00f177c0 -1 journal check: ondisk fsid 00000000-0000-0000-0000-000000000000 doesn't match expected 1992229c-6b1d-42f7-b69b-eb53b430462d, invalid (someone else's?) journal
	SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0b 00 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0b 00 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0b 00 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	2014-09-24 22:01:09.537073 7f0b00f177c0 -1 filestore(/var/lib/ceph/osd/ceph-8) could not find 23c2fcde/osd_superblock/0//-1 in index: (2) No such file or directory
	2014-09-24 22:01:09.547559 7f0b00f177c0 -1 created object store /var/lib/ceph/osd/ceph-8 journal /dev/sdd1 for osd.8 fsid ed095412-5171-4d91-8d7e-5f5678985cd2
	2014-09-24 22:01:09.547657 7f0b00f177c0 -1 auth: error reading file: /var/lib/ceph/osd/ceph-8/keyring: can't open /var/lib/ceph/osd/ceph-8/keyring: (2) No such file or directory
	2014-09-24 22:01:09.547773 7f0b00f177c0 -1 created new key in keyring /var/lib/ceph/osd/ceph-8/keyring
	[root@r83x6u20 ceph]# 
	
	
	[root@r83x6u20 ceph]# ceph auth add osd.6 osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/ceph-6/keyring
	added key for osd.6
	[root@r83x6u20 ceph]# ceph auth add osd.7 osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/ceph-7/keyring
	added key for osd.7
	[root@r83x6u20 ceph]# ceph auth add osd.8 osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/ceph-8/keyring
	added key for osd.8
	[root@r83x6u20 ceph]# ceph osd crush add-bucket r83x6u20 host 
	added bucket r83x6u20 type host to crush map

	[root@r83x6u20 ceph]# ceph osd crush move r83x6u20 root=default
	moved item id -4 name 'r83x6u20' to location {root=default} in crush map

	[root@r83x6u20 ceph]# ceph osd crush add osd.0 1.08 host=r83x6u20
	add item id 0 name 'osd.0' weight 1.08 at location {host=r83x6u20} to crush map
	
	[root@r83x6u20 ceph]# ceph osd create
	6
	[root@r83x6u20 ceph]# ceph osd create
	7
	[root@r83x6u20 ceph]# ceph osd create
	8
	[root@r83x6u20 ceph]# /etc/init.d/ceph start osd.6
	=== osd.6 === 
	create-or-move updating item name 'osd.6' weight 1.08 at location {host=r83x6u20,root=default} to crush map
	Starting Ceph osd.6 on r83x6u20...
	Running as unit run-32253.service.
	[root@r83x6u20 ceph]# /etc/init.d/ceph start osd.7
	=== osd.7 === 
	create-or-move updating item name 'osd.7' weight 1.08 at location {host=r83x6u20,root=default} to crush map
	Starting Ceph osd.7 on r83x6u20...
	Running as unit run-32551.service.
	[root@r83x6u20 ceph]# /etc/init.d/ceph start osd.8
	=== osd.8 === 
	create-or-move updating item name 'osd.8' weight 1.08 at location {host=r83x6u20,root=default} to crush map
	Starting Ceph osd.8 on r83x6u20...
	Running as unit run-428.service.
	
