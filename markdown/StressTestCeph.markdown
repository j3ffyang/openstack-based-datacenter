## Reference
[http://www.sebastien-han.fr/blog/2012/08/26/ceph-benchmarks/](http://www.sebastien-han.fr/blog/2012/08/26/ceph-benchmarks/)

## Local Disk
Sample on 1 OSD on 1 Ceph node

	[root@r83x6u20 ~]# cd /var/lib/ceph/osd/ceph-6/
	[root@r83x6u20 ceph-6]# dd if=/dev/zero of=here bs=5G count=1 oflag=direct
	0+1 records in
	0+1 records out
	2147479552 bytes (2.1 GB) copied, 9.614 s, 223 MB/s

## Fiber Network

On root@r83x6u16 (physical box), which is the 1st Ceph node

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

On root@ctrlr2 (VM), which is the 3rd Controller VM

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

## Create a Pool for Stress

	ceph osd pool create stress_test_sample 256 256
	ceph osd pool set stress_test_sample size 3
	
	rados bench -p stress_test_sample --concurrent-ios=256 300 write
	rados bench -p stress_test_sample --concurrent-ios=256 300 seq

256 concurrent request
300 seconds

## Stress Test on Ceph

Flush cache on each Ceph node

	[root@r83x6u16 ceph-0]# free 
	             total       used       free     shared    buffers     cached
	Mem:     148366580   24082720  124283860      18056        884   20256484
	-/+ buffers/cache:    3825352  144541228
	Swap:      2047996          0    2047996
	[root@r83x6u16 ceph-0]# echo 3 | tee /proc/sys/vm/drop_caches && sync
	3
	[root@r83x6u16 ceph-0]# free 
	             total       used       free     shared    buffers     cached
	Mem:     148366580    3198156  145168424      18056         12      36220
	-/+ buffers/cache:    3161924  145204656
	Swap:      2047996          0    2047996

## From Ceph client to Ceph cluster

	[root@ctrlr2 ceph]# rados bench -p stress_test_sample --concurrent-ios=256 120 write
	
	Total time run:         122.002878
	Total writes made:      4953
	Write size:             4194304
	Bandwidth (MB/sec):     162.390 
	
	Stddev Bandwidth:       97.3952
	Max bandwidth (MB/sec): 856
	Min bandwidth (MB/sec): 0
	Average Latency:        6.15544
	Stddev Latency:         1.13544
	Max latency:            8.91847
	Min latency:            2.38516
	[root@ctrlr2 ceph]# rados bench -p stress_test_sample --concurrent-ios=256 120 write

## Test in Vol (on Ceph) mounted in a VM

	core@coreos-6d13c3b2-4d86-4e5c-bb2e-f0def2ef6501 ~ $ lsblk
	NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
	sr0     11:0    1  422K  0 rom  /media/configdrive
	vda    254:0    0   40G  0 disk 
	|-vda1 254:1    0  128M  0 part 
	|-vda2 254:2    0    2M  0 part 
	|-vda3 254:3    0    1G  0 part /usr
	|-vda4 254:4    0    1G  0 part 
	|-vda6 254:6    0  128M  0 part /usr/share/oem
	|-vda7 254:7    0   64M  0 part 
	`-vda9 254:9    0 37.7G  0 part /var/lib/docker/btrfs
	vdb    254:16   0   20G  0 disk 
	`-vdb1 254:17   0    5G  0 part 
	core@coreos-6d13c3b2-4d86-4e5c-bb2e-f0def2ef6501 ~ $ sudo parted /dev/vdb
	GNU Parted 3.1
	Using /dev/vdb
	Welcome to GNU Parted! Type 'help' to view a list of commands.
	(parted) print                                                            
	Model: Virtio Block Device (virtblk)
	Disk /dev/vdb: 21.5GB
	Sector size (logical/physical): 512B/512B
	Partition Table: msdos
	Disk Flags: 
	
	(parted) mkpart                                                           
	Partition type?  primary/extended? primary                                
	File system type?  [ext2]? xfs                                            
	Start? 0                                                                  
	End? -1s                                                                  
	Warning: The resulting partition is not properly aligned for best performance.
	Ignore/Cancel? I                                                          
	(parted) print                                                            
	Model: Virtio Block Device (virtblk)
	Disk /dev/vdb: 21.5GB
	Sector size (logical/physical): 512B/512B
	Partition Table: msdos
	Disk Flags: 
	
	Number  Start  End     Size    Type     File system  Flags
	 1      512B   21.5GB  21.5GB  primary
	
	(parted) quit                                                             
	Information: You may need to update /etc/fstab.
	
	core@coreos-6d13c3b2-4d86-4e5c-bb2e-f0def2ef6501 ~ $ sudo mkfs -t ext4 /dev/vdb1
	mke2fs 1.42.9 (28-Dec-2013)
	Filesystem label=
	OS type: Linux
	Block size=4096 (log=2)
	Fragment size=4096 (log=2)
	Stride=0 blocks, Stripe width=0 blocks
	1310720 inodes, 5242879 blocks
	262143 blocks (5.00%) reserved for the super user
	First data block=0
	Maximum filesystem blocks=4294967296
	160 block groups
	32768 blocks per group, 32768 fragments per group
	8192 inodes per group
	Superblock backups stored on blocks: 
		32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208, 
		4096000
	
	Allocating group tables: done                            
	Writing inode tables: done                            
	Creating journal (32768 blocks): done
	Writing superblocks and filesystem accounting information: done   
	
	core@coreos-6d13c3b2-4d86-4e5c-bb2e-f0def2ef6501 ~ $ sudo mount /dev/vdb1 /mnt
	core@coreos-6d13c3b2-4d86-4e5c-bb2e-f0def2ef6501 ~ $ cd /mnt
	core@coreos-6d13c3b2-4d86-4e5c-bb2e-f0def2ef6501 /mnt $ sudo dd if=/dev/zero of=/mnt/deleteme bs=4M count=1024
	1024+0 records in
	1024+0 records out
	4294967296 bytes (4.3 GB) copied, 22.2571 s, 193 MB/s
	core@coreos-6d13c3b2-4d86-4e5c-bb2e-f0def2ef6501 /mnt $ ls -tl
	total 4194324
	-rw-r--r-- 1 root root 4294967296 Nov  6 18:09 deleteme
	drwx------ 2 root root      16384 Nov  6 18:04 lost+found

### Conclusion    
4294967296 bytes (4.3 GB) copied, 22.2571 s, 193 MB/s

## fio against all Ceph node

	yum install fio -y

	[root@r83x6u20 ~]# fio -filename=/dev/sdc2 -direct=1 -iodepth 1 -thread -rw=randrw -rwmixread=70 -ioengine=psync -bs=4k -size=100G -numjobs=30 -runtime=100 -group_reporting -name=sdc_4k
	sdc_4k: (g=0): rw=randrw, bs=4K-4K/4K-4K/4K-4K, ioengine=psync, iodepth=1
	...
	fio-2.1.11
	Starting 30 threads
	Jobs: 30 (f=30): [m(30)] [100.0% done] [2524KB/1040KB/0KB /s] [631/260/0 iops] [eta 00m:00s]
	sdc_4k: (groupid=0, jobs=30): err= 0: pid=1679: Fri Nov  7 13:53:40 2014
	  read : io=256436KB, bw=2560.8KB/s, iops=640, runt=100140msec
	    clat (usec): min=62, max=739327, avg=46566.87, stdev=55388.31
	     lat (usec): min=62, max=739327, avg=46567.04, stdev=55388.32
	    clat percentiles (msec):
	     |  1.00th=[    3],  5.00th=[    5], 10.00th=[    6], 20.00th=[    9],
	     | 30.00th=[   14], 40.00th=[   19], 50.00th=[   27], 60.00th=[   38],
	     | 70.00th=[   52], 80.00th=[   74], 90.00th=[  114], 95.00th=[  157],
	     | 99.00th=[  265], 99.50th=[  318], 99.90th=[  429], 99.95th=[  474],
	     | 99.99th=[  603]
	    bw (KB  /s): min=    5, max=  199, per=3.36%, avg=86.05, stdev=29.24
	  write: io=102896KB, bw=1027.6KB/s, iops=256, runt=100140msec
	    clat (usec): min=48, max=523444, avg=601.83, stdev=6557.84
	     lat (usec): min=48, max=523444, avg=602.12, stdev=6557.84
	    clat percentiles (usec):
	     |  1.00th=[   51],  5.00th=[   53], 10.00th=[   55], 20.00th=[   72],
	     | 30.00th=[   77], 40.00th=[   79], 50.00th=[   81], 60.00th=[   82],
	     | 70.00th=[   86], 80.00th=[  122], 90.00th=[  163], 95.00th=[  596],
	     | 99.00th=[ 2928], 99.50th=[38656], 99.90th=[98816], 99.95th=[109056],
	     | 99.99th=[123392]
	    bw (KB  /s): min=    4, max=  149, per=3.44%, avg=35.38, stdev=19.94
	    lat (usec) : 50=0.03%, 100=21.79%, 250=5.24%, 500=0.13%, 750=0.23%
	    lat (usec) : 1000=0.11%
	    lat (msec) : 2=0.67%, 4=3.74%, 10=13.03%, 20=13.29%, 50=19.64%
	    lat (msec) : 100=13.15%, 250=8.07%, 500=0.84%, 750=0.03%
	  cpu          : usr=0.02%, sys=0.04%, ctx=90390, majf=0, minf=11
	  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
	     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
	     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
	     issued    : total=r=64109/w=25724/d=0, short=r=0/w=0/d=0
	     latency   : target=0, window=0, percentile=100.00%, depth=1
	
	Run status group 0 (all jobs):
	   READ: io=256436KB, aggrb=2560KB/s, minb=2560KB/s, maxb=2560KB/s, mint=100140msec, maxt=100140msec
	  WRITE: io=102896KB, aggrb=1027KB/s, minb=1027KB/s, maxb=1027KB/s, mint=100140msec, maxt=100140msec
	
	Disk stats (read/write):
	  sdc: ios=64078/25762, merge=566/8, ticks=2978487/15435, in_queue=2995497, util=100.00%
	[root@r83x6u20 ~]# 


