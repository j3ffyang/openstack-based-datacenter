## Ceph Architecture
![Ceph Architecture](images/20140918_ceph_stack.png)

Credit: [http://docs.ceph.com](http://docs.ceph.com/docs/master/architecture/#the-ceph-storage-cluster)

## Ceph Network
![Ceph Network](images/20140918_ceph_nw.png)
Credit: [http://ceph.com](http://ceph.com/docs/v0.80.5/rados/configuration/network-config-ref/)

## Create [Ceph Configure File](samples/ceph/ceph.conf)
Public Network = 10.0.0.0/16
Ceph Cluster   = 10.10.0.0/16

## Install

	yum install ceph

## Configure

	[root@r83x6u16 ceph]# ceph-authtool --create-keyring /tmp/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *' 
	creating /tmp/ceph.mon.keyring

	[root@r83x6u16 ceph]# ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --set-uid=0 --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow' 
	creating /etc/ceph/ceph.client.admin.keyring

	[root@r83x6u16 ceph]# ceph-authtool /tmp/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring 
	importing contents of /etc/ceph/ceph.client.admin.keyring into /tmp/ceph.mon.keyring

	[root@r83x6u16 ceph]# uuidgen
	ed095412-5171-4d91-8d7e-5f5678985cd2

	[root@r83x6u16 ceph]# monmaptool --create --add r83x6u16 10.0.0.201 --fsid ed095412-5171-4d91-8d7e-5f5678985cd2 /tmp/monmap
	monmaptool: monmap file /tmp/monmap
	monmaptool: set fsid to ed095412-5171-4d91-8d7e-5f5678985cd2
	monmaptool: writing epoch 0 to /tmp/monmap (1 monitors)

	[root@r83x6u16 network-scripts]# ceph-mon --mkfs -i r83x6u16 --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring 
	ceph-mon: set fsid to ed095412-5171-4d91-8d7e-5f5678985cd2
	ceph-mon: created monfs at /var/lib/ceph/mon/ceph-r83x6u16 for mon.r83x6u16

Edit and Verify /etc/ceph/ceph.conf, then Start Ceph Mon
	/etc/init.d/ceph start

Create OSD (ceph-0 is 1st OSD)

	[root@r83x6u16 ceph]# ceph osd create

	[root@r83x6u16 ceph]# mkdir -p /var/lib/ceph/osd/ceph-0

	[root@r83x6u16 ceph]# mkfs -t xfs -i size=2048 -f /dev/sdb2

	[root@r83x6u16 ceph]# mount -t xfs /dev/sdb2 /var/lib/ceph/osd/ceph-0 

	[root@r83x6u16 ceph]# ceph-osd -i 0 --mkfs --mkkey 
	2014-09-17 19:49:29.941849 7fe90c1fb7c0 -1 journal FileJournal::_open: disabling aio for non-block journal.  Use journal_force_aio to force use of aio anyway
	2014-09-17 19:49:29.948735 7fe90c1fb7c0 -1 journal FileJournal::_open: disabling aio for non-block journal.  Use journal_force_aio to force use of aio anyway
	2014-09-17 19:49:29.949391 7fe90c1fb7c0 -1 filestore(/var/lib/ceph/osd/ceph-0) could not find 23c2fcde/osd_superblock/0//-1 in index: (2) No such file or directory
	2014-09-17 19:49:29.960856 7fe90c1fb7c0 -1 created object store /var/lib/ceph/osd/ceph-0 journal /var/lib/ceph/osd/ceph-0/journal for osd.0 fsid ed095412-5171-4d91-8d7e-5f5678985cd2
	2014-09-17 19:49:29.960953 7fe90c1fb7c0 -1 auth: error reading file: /var/lib/ceph/osd/ceph-0/keyring: can't open /var/lib/ceph/osd/ceph-0/keyring: (2) No such file or directory
	2014-09-17 19:49:29.961073 7fe90c1fb7c0 -1 created new key in keyring /var/lib/ceph/osd/ceph-0/keyring

	[root@r83x6u16 ceph]# ceph auth add osd.0 osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/ceph-0/keyring 
	added key for osd.0

	[root@r83x6u16 ceph]# ceph osd crush add-bucket r83x6u16  host 
	added bucket r83x6u16 type host to crush map

	[root@r83x6u16 ceph]# ceph osd crush move r83x6u16 root=default
	moved item id -2 name 'r83x6u16' to location {root=default} in crush map

	[root@r83x6u16 ceph]# ceph osd crush add osd.0 1.08 host=r83x6u16 
	add item id 0 name 'osd.0' weight 1.08 at location {host=r83x6u16} to crush map
        
	[root@r83x6u16 ceph-0]# /etc/init.d/ceph start osd.0
	=== osd.0 === 
	create-or-move updated item name 'osd.0' weight 1.08 at location {host=r83x6u16,root=default} to crush map
	Starting Ceph osd.0 on r83x6u16...
	Running as unit run-22215.service.
        
	[root@r83x6u16 ceph-0]# ceph osd ls
	0

Repeat the above step for 2nd and 3rd OSD (ceph-1 is the 2nd OSD and ceph-2 the 3rd)

	ceph osd create
	mkdir -p /var/lib/ceph/osd/ceph-1
	mkfs -t xfs -i size=2048 -f /dev/sdc2
	mount -t xfs /dev/sdb2 /var/lib/ceph/osd/ceph-1
	ceph-osd -i 1 --mkfs --mkkey
	ceph auth add osd.1 osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/ceph-1/keyring
	ceph osd crush add osd.1 1.08 host=r83x6u16
	/etc/init.d/ceph start osd.1
	ceph osd ls

## Update /etc/fstab

	#
	# /etc/fstab
	# Created by anaconda on Sat Sep 13 15:45:15 2014
	#
	# Accessible filesystems, by reference, are maintained under '/dev/disk'
	# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
	#
	UUID=1f533ea5-8b64-4ffb-bda4-afcdefc00faa /                       xfs     defaults        1 1
	UUID=52ab55b8-6ec4-4cd0-ba90-42d57b500056 /boot                   xfs     defaults        1 2
	UUID=68B1-4A17          /boot/efi               vfat    umask=0077,shortname=winnt 0 0
	UUID=b9912f1a-9542-4986-8edc-4bc786dc78f0 swap                    swap    defaults        0 0
	
	/dev/sdb2               /var/lib/ceph/osd/ceph-0                  xfs     defaults        0 2
	/dev/sdc2               /var/lib/ceph/osd/ceph-1                  xfs     defaults        0 2
	/dev/sdd2               /var/lib/ceph/osd/ceph-2                  xfs     defaults        0 2
	
 
## Tips
Stop Ceph Cluster

	touch /var/run/ceph/mon.r83x6u16.pid; echo `ps -ef | grep "ceph-mon" | grep -v grep | tail -n1 | awk '{print $2}'` > /var/run/ceph/mon.r83x6u16.pid; /etc/init.d/ceph stop

	
