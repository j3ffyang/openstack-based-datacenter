## Prepare Node
Configure public (10.0/16) and Ceph cluster (10.10/16) network
Update hostname    
Update /etc/hosts    
Update /etc/yum.repos.d    
[Partition](CephPartition.markdown)

## Install Ceph

## Update [/etc/ceph/ceph.conf](samples/ceph/ceph.conf)
Add osd blocks

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
	
