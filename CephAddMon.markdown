## Add an additional monitor

Reference > [http://ceph.com/docs/firefly/rados/operations/add-or-rm-mons/](http://ceph.com/docs/firefly/rados/operations/add-or-rm-mons/)

In our case, we choose r83x6u18 (172.16.0.202) as the 2nd node to host the 2nd Ceph monitor

Log into r83x6u18

## Export mon.keyring

	ceph auth get mon. -o /tmp/ceph.mon.keyring

## Get the monmap

	ceph mon getmap -o /tmp/monmap

## Create mon dir

	ceph-mon -i r83x6u18 --mkfs --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring
