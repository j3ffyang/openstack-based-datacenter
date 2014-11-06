## Increase Thread

	[root@r83x6u16 ~]# ceph tell osd.* injectargs '--osd-op-threads 4'
	osd.0: osd_op_threads = '4' 
	osd.1: osd_op_threads = '4' 
	osd.2: osd_op_threads = '4' 
	osd.3: osd_op_threads = '4' 
	osd.4: osd_op_threads = '4' 
	osd.5: osd_op_threads = '4' 
	osd.6: osd_op_threads = '4' 
	osd.7: osd_op_threads = '4' 
	osd.8: osd_op_threads = '4' 
	[root@r83x6u16 ~]# 
	[root@r83x6u16 ~]# ceph --admin-daemon /var/run/ceph/ceph-osd.0.asok config show | less

