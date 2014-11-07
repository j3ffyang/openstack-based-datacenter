## Fiber Network

On root@r83x6u16 (physical box), which is the 1st Ceph node, between individual Ceph nodes

	[root@r83x6u16 ceph-0]# iperf3 -s
	-----------------------------------------------------------
	Server listening on 5201
	-----------------------------------------------------------

On root@r83x6u18 (physical box), which is the 2nd Ceph node
	
	[root@r83x6u18 ceph-3]# iperf3 -c 10.10.0.201 -i1 -t10
	Connecting to host 10.10.0.201, port 5201
	[  4] local 10.10.0.202 port 59376 connected to 10.10.0.201 port 5201
	[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
	[  4]   0.00-1.00   sec   782 MBytes  6.56 Gbits/sec   79    318 KBytes       
	[  4]   1.00-2.00   sec  1.09 GBytes  9.38 Gbits/sec    0    389 KBytes       
	[  4]   2.00-3.00   sec  1.09 GBytes  9.40 Gbits/sec    0    448 KBytes       
	[  4]   3.00-4.00   sec  1.09 GBytes  9.40 Gbits/sec    0    501 KBytes       
	[  4]   4.00-5.00   sec  1.09 GBytes  9.40 Gbits/sec    0    546 KBytes       
	[  4]   5.00-6.00   sec  1.09 GBytes  9.40 Gbits/sec    0    587 KBytes       
	[  4]   6.00-7.00   sec  1.09 GBytes  9.40 Gbits/sec    0    621 KBytes       
	[  4]   7.00-8.00   sec  1.09 GBytes  9.40 Gbits/sec    0    648 KBytes       
	[  4]   8.00-9.00   sec  1.09 GBytes  9.40 Gbits/sec    0    670 KBytes       
	[  4]   9.00-10.00  sec  1.09 GBytes  9.40 Gbits/sec    0    693 KBytes       
	- - - - - - - - - - - - - - - - - - - - - - - - -
	[ ID] Interval           Transfer     Bandwidth       Retr
	[  4]   0.00-10.00  sec  10.6 GBytes  9.12 Gbits/sec   79             sender
	[  4]   0.00-10.00  sec  10.6 GBytes  9.11 Gbits/sec                  receiver
	
	iperf Done.

On root@ctrlr2 (VM), which is the 3rd Controller VM, against Ceph node

	[root@ctrlr2 ~]# iperf3 -c 10.0.0.201 -i1 -t10
	Connecting to host 10.0.0.201, port 5201
	[  4] local 10.0.0.35 port 62188 connected to 10.0.0.201 port 5201
	[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
	[  4]   0.00-1.00   sec   811 MBytes  6.79 Gbits/sec  199    489 KBytes       
	[  4]   1.00-2.00   sec  1.06 GBytes  9.08 Gbits/sec    0    539 KBytes       
	[  4]   2.00-3.00   sec  1.01 GBytes  8.66 Gbits/sec    0    576 KBytes       
	[  4]   3.00-4.00   sec  1.04 GBytes  8.94 Gbits/sec  117    308 KBytes       
	[  4]   4.00-5.00   sec   879 MBytes  7.36 Gbits/sec    0    364 KBytes       
	[  4]   5.00-6.00   sec   975 MBytes  8.19 Gbits/sec    0    415 KBytes       
	[  4]   6.00-7.00   sec  1016 MBytes  8.52 Gbits/sec    0    463 KBytes       
	[  4]   7.00-8.00   sec  1021 MBytes  8.56 Gbits/sec    0    505 KBytes       
	[  4]   8.00-9.00   sec   920 MBytes  7.71 Gbits/sec    0    536 KBytes       
	[  4]   9.00-10.00  sec  1.04 GBytes  8.96 Gbits/sec    0    573 KBytes       
	- - - - - - - - - - - - - - - - - - - - - - - - -
	[ ID] Interval           Transfer     Bandwidth       Retr
	[  4]   0.00-10.00  sec  9.64 GBytes  8.28 Gbits/sec  316             sender
	[  4]   0.00-10.00  sec  9.64 GBytes  8.28 Gbits/sec                  receiver
	
	iperf Done.

### Conclusion:    
1. All traffic are through fiber network    
2. Test covers both physical boxes (average 9.1 Gbits/sec) and VM (average 8.28 Gbits/sec)
