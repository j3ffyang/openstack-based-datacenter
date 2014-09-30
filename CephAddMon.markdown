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

	[root@r83x6u18 temp]# ceph mon add r83x6u18 10.0.0.202

Log in the same box in Another terminal

	/etc/init.d/ceph start mon.r83x6u18

Then you'd see the mon.r83x6u18 added into cluster

## Update All nodes (doing this on Chef)

	cd /opt/git/mustang/; git pull
	scp samples/ceph/ceph.conf 172.16.0.201:/etc/ceph

Do the same onto other Ceph nodes

## Sync NTP then Restart all Ceph daemon on All Ceph nodes (doing this on Chef)
	ssh -t 172.16.0.203 "touch /var/run/ceph/mon.r83x6u20.pid; echo `ps -ef | grep "ceph-mon" | grep -v grep | tail -n1 | awk '{print $2}'` > /var/run/ceph/mon.r83x6u20.pid; /etc/init.d/ceph restart"

Do this on ALL ceph nodes

## Tips
If ceph -s gets screwed up, you could run the following command without having to re- generate the cluster

	ceph-mon -i r83x6u16 --inject-monmap /tmp/ceph.map
