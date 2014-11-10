## Ceph Service Crashing
November 09, 2014, there was a Ceph service crash, caused by an interrupted fiber NIC. Basic symptom was that the VM launched on Ceph became unaccessible.

## Check Status

	[root@r83x6u20 ceph]# ceph -s
	    cluster ed095412-5171-4d91-8d7e-5f5678985cd2
	     health HEALTH_ERR 9 pgs inconsistent; 9 scrub errors
	     monmap e5: 3 mons at {r83x6u16=10.0.0.201:6789/0,r83x6u18=10.0.0.202:6789/0,r83x6u20=10.0.0.203:6789/0}, election epoch 452, quorum 0,1,2 r83x6u16,r83x6u18,r83x6u20
	     osdmap e1250: 9 osds: 9 up, 9 in
	      pgmap v231022: 704 pgs, 6 pools, 177 GB data, 45884 objects
	            438 GB used, 9514 GB / 9952 GB avail
	                 695 active+clean
	                   9 active+clean+inconsistent
	  client io 70503 B/s wr, 26 op/s

## Check OSD. No error

	[root@r83x6u20 ceph]# ceph osd dump
	epoch 1250
	fsid ed095412-5171-4d91-8d7e-5f5678985cd2
	created 2014-09-25 20:52:52.336701
	modified 2014-11-10 10:25:04.703463
	flags 
	pool 0 'data' replicated size 2 min_size 1 crush_ruleset 0 object_hash rjenkins pg_num 64 pgp_num 64 last_change 1 flags hashpspool crash_replay_interval 45 stripe_width 0
	pool 1 'metadata' replicated size 2 min_size 1 crush_ruleset 0 object_hash rjenkins pg_num 64 pgp_num 64 last_change 1 flags hashpspool stripe_width 0
	pool 2 'rbd' replicated size 2 min_size 1 crush_ruleset 0 object_hash rjenkins pg_num 64 pgp_num 64 last_change 1 flags hashpspool stripe_width 0
	pool 3 'volumes' replicated size 3 min_size 1 crush_ruleset 0 object_hash rjenkins pg_num 128 pgp_num 128 last_change 574 flags hashpspool stripe_width 0
	pool 4 'images' replicated size 3 min_size 1 crush_ruleset 0 object_hash rjenkins pg_num 128 pgp_num 128 last_change 601 flags hashpspool stripe_width 0
		removed_snaps [1~1,3~2]
	pool 5 'stress_test_sample' replicated size 3 min_size 1 crush_ruleset 0 object_hash rjenkins pg_num 256 pgp_num 256 last_change 670 flags hashpspool stripe_width 0
	max_osd 9
	osd.0 up   in  weight 1 up_from 783 up_thru 1248 down_at 782 last_clean_interval [10,782) 10.0.0.201:6800/7828 10.10.0.201:6800/3007828 10.10.0.201:6807/3007828 10.0.0.201:6807/3007828 exists,up be1b7012-d522-4fde-80b5-1e1cdc340519
	osd.1 up   in  weight 1 up_from 665 up_thru 1248 down_at 663 last_clean_interval [12,663) 10.0.0.201:6803/8069 10.10.0.201:6803/2008069 10.10.0.201:6804/2008069 10.0.0.201:6804/2008069 exists,up fdbddf74-4326-4649-9040-b3a08faff9c1
	osd.2 up   in  weight 1 up_from 873 up_thru 1249 down_at 872 last_clean_interval [14,872) 10.0.0.201:6806/8329 10.10.0.201:6801/4008329 10.10.0.201:6802/4008329 10.0.0.201:6801/4008329 exists,up dc6561d2-d2e0-4d4f-8094-ffee86dd74e0
	osd.3 up   in  weight 1 up_from 664 up_thru 1247 down_at 663 last_clean_interval [27,663) 10.0.0.202:6800/6146 10.10.0.202:6803/47006146 10.10.0.202:6804/47006146 10.0.0.202:6801/47006146 exists,up d5765f4c-4036-4d07-83ba-bc893357858c
	osd.4 up   in  weight 1 up_from 1175 up_thru 1249 down_at 1174 last_clean_interval [29,1174) 10.0.0.202:6803/6395 10.10.0.202:6800/49006395 10.10.0.202:6801/49006395 10.0.0.202:6807/49006395 exists,up 0ec14685-6780-4997-9c3a-46dbe9469b7c
	osd.5 up   in  weight 1 up_from 891 up_thru 1245 down_at 888 last_clean_interval [32,890) 10.0.0.202:6806/6672 10.10.0.202:6805/49006672 10.10.0.202:6807/49006672 10.0.0.202:6804/49006672 exists,up 7170e532-e804-4531-991e-fa69ffb0d36f
	osd.6 up   in  weight 1 up_from 1148 up_thru 1245 down_at 1146 last_clean_interval [982,1147) 10.0.0.203:6800/4625 10.10.0.203:6806/1004625 10.10.0.203:6807/1004625 10.0.0.203:6809/1004625 exists,up 81548213-3012-45d2-82db-32379760ba24
	osd.7 up   in  weight 1 up_from 1245 up_thru 1249 down_at 1174 last_clean_interval [1083,1173) 10.0.0.203:6801/2927 10.10.0.203:6800/2927 10.10.0.203:6801/2927 10.0.0.203:6803/2927 exists,up b4bdc7a4-2e3a-4614-8406-96710c831a68
	osd.8 up   in  weight 1 up_from 993 up_thru 1245 down_at 992 last_clean_interval [119,981) 10.0.0.203:6804/5689 10.10.0.203:6802/5689 10.10.0.203:6804/5689 10.0.0.203:6807/5689 exists,up ab117c1d-21ed-4a20-81a3-890b39d40146

## List 9 page groups in error

	[root@r83x6u20 ceph]# ceph health detail
	HEALTH_ERR 9 pgs inconsistent; 9 scrub errors
	pg 5.a0 is active+clean+inconsistent, acting [1,2,0]
	pg 5.9d is active+clean+inconsistent, acting [8,0,5]
	pg 5.43 is active+clean+inconsistent, acting [0,4,7]
	pg 5.3a is active+clean+inconsistent, acting [4,2,5]
	pg 5.31 is active+clean+inconsistent, acting [0,2,1]
	pg 5.18 is active+clean+inconsistent, acting [1,3,5]
	pg 5.1d is active+clean+inconsistent, acting [4,6,1]
	pg 5.13 is active+clean+inconsistent, acting [1,3,5]
	pg 5.f7 is active+clean+inconsistent, acting [5,0,2]
	9 scrub errors

## Repair page group

	[root@r83x6u20 ceph]# for i in `ceph health detail | grep ^pg | awk '{print $2}'`; do ceph pg repair $i; done
	instructing pg 5.a0 on osd.1 to repair
	instructing pg 5.9d on osd.8 to repair
	instructing pg 5.43 on osd.0 to repair
	instructing pg 5.3a on osd.4 to repair
	instructing pg 5.31 on osd.0 to repair
	instructing pg 5.18 on osd.1 to repair
	instructing pg 5.1d on osd.4 to repair
	instructing pg 5.13 on osd.1 to repair
	instructing pg 5.f7 on osd.5 to repair

## Check status again
Check status during repairing

	[root@r83x6u20 ceph]# ceph -s
	    cluster ed095412-5171-4d91-8d7e-5f5678985cd2
	     health HEALTH_ERR 8 pgs inconsistent; 1 pgs repair; 8 scrub errors
	     monmap e5: 3 mons at {r83x6u16=10.0.0.201:6789/0,r83x6u18=10.0.0.202:6789/0,r83x6u20=10.0.0.203:6789/0}, election epoch 452, quorum 0,1,2 r83x6u16,r83x6u18,r83x6u20
	     osdmap e1250: 9 osds: 9 up, 9 in
	      pgmap v231076: 704 pgs, 6 pools, 177 GB data, 45884 objects
	            438 GB used, 9514 GB / 9952 GB avail
	                   1 active+clean+scrubbing+deep+inconsistent+repair
	                 696 active+clean
	                   7 active+clean+inconsistent
	recovery io 23715 kB/s, 5 objects/s

Check status after repair

	[root@r83x6u20 ceph]# ceph -s
	    cluster ed095412-5171-4d91-8d7e-5f5678985cd2
	     health HEALTH_OK
	     monmap e5: 3 mons at {r83x6u16=10.0.0.201:6789/0,r83x6u18=10.0.0.202:6789/0,r83x6u20=10.0.0.203:6789/0}, election epoch 452, quorum 0,1,2 r83x6u16,r83x6u18,r83x6u20
	     osdmap e1250: 9 osds: 9 up, 9 in
	      pgmap v231102: 704 pgs, 6 pools, 177 GB data, 45884 objects
	            439 GB used, 9513 GB / 9952 GB avail
	                 704 active+clean
	recovery io 10210 kB/s, 2 objects/s
	  client io 319 B/s wr, 0 op/s
	[root@r83x6u20 ceph]# 
