## Reference
[http://www.sebastien-han.fr/blog/2012/08/26/ceph-benchmarks/](http://www.sebastien-han.fr/blog/2012/08/26/ceph-benchmarks/)

## Local Disk
Sample on 1 OSD on 1 Ceph node

	[root@r83x6u20 ~]# cd /var/lib/ceph/osd/ceph-6/
	[root@r83x6u20 ceph-6]# dd if=/dev/zero of=here bs=5G count=1 oflag=direct
	0+1 records in
	0+1 records out
	2147479552 bytes (2.1 GB) copied, 9.614 s, 223 MB/s

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

## fio on local Ceph node

	yum install fio -y

	[root@r83x6u20 ~]# fio -filename=/dev/sdc2 -direct=1 -iodepth 1 -thread -rw=randrw -rwmixread=70 -ioengine=psync -bs=16k -size=200G -numjobs=30 -runtime=100 -group_reporting -name=sdc_4k
	sdc_4k: (g=0): rw=randrw, bs=16K-16K/16K-16K/16K-16K, ioengine=psync, iodepth=1
	...
	fio-2.1.11
	Starting 30 threads
	Jobs: 30 (f=30): [m(30)] [100.0% done] [8176KB/2464KB/0KB /s] [511/154/0 iops] [eta 00m:00s]
	sdc_4k: (groupid=0, jobs=30): err= 0: pid=1954: Fri Nov  7 14:57:56 2014
	  read : io=406992KB, bw=4066.5KB/s, iops=254, runt=100085msec
	    clat (usec): min=88, max=2618.3K, avg=98808.05, stdev=194430.05
	     lat (usec): min=88, max=2618.3K, avg=98808.38, stdev=194430.06
	    clat percentiles (msec):
	     |  1.00th=[    4],  5.00th=[    6], 10.00th=[    8], 20.00th=[   13],
	     | 30.00th=[   20], 40.00th=[   29], 50.00th=[   41], 60.00th=[   58],
	     | 70.00th=[   80], 80.00th=[  118], 90.00th=[  212], 95.00th=[  437],
	     | 99.00th=[ 1090], 99.50th=[ 1352], 99.90th=[ 2008], 99.95th=[ 2212],
	     | 99.99th=[ 2442]
	    bw (KB  /s): min=    1, max=  724, per=4.55%, avg=185.02, stdev=140.35
	  write: io=163472KB, bw=1633.4KB/s, iops=102, runt=100085msec
	    clat (usec): min=68, max=663854, avg=23792.50, stdev=91810.74
	     lat (usec): min=69, max=663855, avg=23793.58, stdev=91810.79
	    clat percentiles (usec):
	     |  1.00th=[   81],  5.00th=[  107], 10.00th=[  119], 20.00th=[  143],
	     | 30.00th=[  151], 40.00th=[  163], 50.00th=[  179], 60.00th=[  187],
	     | 70.00th=[  199], 80.00th=[  221], 90.00th=[ 9664], 95.00th=[218112],
	     | 99.00th=[440320], 99.50th=[440320], 99.90th=[659456], 99.95th=[659456],
	     | 99.99th=[659456]
	    bw (KB  /s): min=    5, max=  440, per=6.00%, avg=97.91, stdev=71.72
	    lat (usec) : 100=0.91%, 250=23.65%, 500=0.51%, 750=0.29%, 1000=0.07%
	    lat (msec) : 2=0.14%, 4=1.81%, 10=10.02%, 20=10.68%, 50=18.39%
	    lat (msec) : 100=14.88%, 250=11.88%, 500=4.47%, 750=1.11%, 1000=0.38%
	    lat (msec) : 2000=0.72%, >=2000=0.07%
	  cpu          : usr=0.01%, sys=0.20%, ctx=36934, majf=0, minf=14
	  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
	     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
	     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
	     issued    : total=r=25437/w=10217/d=0, short=r=0/w=0/d=0
	     latency   : target=0, window=0, percentile=100.00%, depth=1
	
	Run status group 0 (all jobs):
	   READ: io=406992KB, aggrb=4066KB/s, minb=4066KB/s, maxb=4066KB/s, mint=100085msec, maxt=100085msec
	  WRITE: io=163472KB, aggrb=1633KB/s, minb=1633KB/s, maxb=1633KB/s, mint=100085msec, maxt=100085msec
	
	Disk stats (read/write):
	  sdc: ios=25421/12046, merge=7/104, ticks=2511315/27916736, in_queue=7019367, util=100.00%

### Conclusion

Read  iops=254    
Write iops=102

## Test fio within VM against volume from Ceph node

	[root@localhost yum.repos.d]# fio -filename=/dev/vda -direct=1 -iodepth 1 -thread -rw=randrw -rwmixread=70 -ioengine=psync -bs=16k -size=200G -numjobs=30 -runtime=100 -group_reporting -name=vda_16k
	vda_16k: (g=0): rw=randrw, bs=16K-16K/16K-16K/16K-16K, ioengine=psync, iodepth=1
	...
	fio-2.1.11
	Starting 30 threads
	Jobs: 27 (f=27): [m(10),_(1),m(4),_(1),m(10),_(1),m(3)] [25.6% done] [0KB/47KB/0KB /s] [0/2/0 iops] [eta 05m:00s]
	vda_16k: (groupid=0, jobs=30): err= 0: pid=8952: Fri Nov  7 01:22:38 2014
	  read : io=2014.6MB, bw=20136KB/s, iops=1258, runt=102451msec
	    clat (usec): min=764, max=3729.4K, avg=2006.43, stdev=21054.86
	     lat (usec): min=764, max=3729.4K, avg=2006.86, stdev=21054.86
	    clat percentiles (usec):
	     |  1.00th=[ 1064],  5.00th=[ 1176], 10.00th=[ 1256], 20.00th=[ 1336],
	     | 30.00th=[ 1400], 40.00th=[ 1464], 50.00th=[ 1528], 60.00th=[ 1608],
	     | 70.00th=[ 1704], 80.00th=[ 1832], 90.00th=[ 2064], 95.00th=[ 2320],
	     | 99.00th=[ 3088], 99.50th=[ 3696], 99.90th=[68096], 99.95th=[175104],
	     | 99.99th=[897024]
	    bw (KB  /s): min=    2, max= 2752, per=4.93%, avg=992.11, stdev=661.23
	  write: io=870128KB, bw=8493.2KB/s, iops=530, runt=102451msec
	    clat (msec): min=2, max=5473, avg=51.71, stdev=242.70
	     lat (msec): min=2, max=5473, avg=51.72, stdev=242.70
	    clat percentiles (msec):
	     |  1.00th=[    4],  5.00th=[    4], 10.00th=[    5], 20.00th=[   12],
	     | 30.00th=[   14], 40.00th=[   16], 50.00th=[   19], 60.00th=[   25],
	     | 70.00th=[   30], 80.00th=[   36], 90.00th=[   45], 95.00th=[   72],
	     | 99.00th=[  865], 99.50th=[ 1663], 99.90th=[ 4490], 99.95th=[ 5014],
	     | 99.99th=[ 5473]
	    bw (KB  /s): min=    2, max= 1035, per=4.81%, avg=408.73, stdev=261.46
	    lat (usec) : 1000=0.23%
	    lat (msec) : 2=61.56%, 4=10.45%, 10=2.86%, 20=10.54%, 50=11.98%
	    lat (msec) : 100=1.14%, 250=0.47%, 500=0.23%, 750=0.18%, 1000=0.14%
	    lat (msec) : 2000=0.15%, >=2000=0.08%
	  cpu          : usr=0.05%, sys=0.16%, ctx=183371, majf=0, minf=49
	  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
	     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
	     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
	     issued    : total=r=128933/w=54383/d=0, short=r=0/w=0/d=0
	     latency   : target=0, window=0, percentile=100.00%, depth=1
	
	Run status group 0 (all jobs):
	   READ: io=2014.6MB, aggrb=20135KB/s, minb=20135KB/s, maxb=20135KB/s, mint=102451msec, maxt=102451msec
	  WRITE: io=870128KB, aggrb=8493KB/s, minb=8493KB/s, maxb=8493KB/s, mint=102451msec, maxt=102451msec
	
	Disk stats (read/write):
	  vda: ios=129024/54380, merge=0/9, ticks=251089/2707506, in_queue=3098204, util=100.00%
	[root@localhost yum.repos.d]# 

### Conclusion

Read  iops=1258    
Write iops=530
