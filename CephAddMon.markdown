## Add an additional monitor

Reference > [http://ceph.com/docs/firefly/rados/operations/add-or-rm-mons/](http://ceph.com/docs/firefly/rados/operations/add-or-rm-mons/)

In our case, we choose r83x6u18 (172.16.0.202) as the 2nd node to host the 2nd Ceph monitor

Log into r83x6u18

	[root@r83x6u18 temp]# mkdir -p /var/lib/ceph/mon/ceph-r83x6u18
	[root@r83x6u18 ~]# mkdir -p ~/temp

	[root@r83x6u18 ~]# ceph auth get mon. -o ~/temp/ceph.mon.keyring
	exported keyring for mon.

	[root@r83x6u18 temp]# ceph mon getmap -o ~/temp/ceph.map
	got monmap epoch 1

	[root@r83x6u18 temp]# ceph-mon -i r83x6u18 --mkfs --monmap ~/temp/ceph.map --keyring ~/temp/ceph.mon.keyring 
	ceph-mon: set fsid to ed095412-5171-4d91-8d7e-5f5678985cd2
	ceph-mon: created monfs at /var/lib/ceph/mon/ceph-r83x6u18 for mon.r83x6u18

	[root@r83x6u18 temp]# ceph mon add r83x6u18 172.16.0.202

