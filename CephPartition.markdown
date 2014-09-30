## Partition Layout

The partition layout BEFORE partition remade by parted. You can see 3 groups of RAID0 exist in raw mode

	[root@r83x6u16 ~]# lsblk
	NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
	sda      8:0    0 557.9G  0 disk 
	├─sda1   8:1    0   200M  0 part /boot/efi
	├─sda2   8:2    0   250M  0 part /boot
	├─sda3   8:3    0     2G  0 part [SWAP]
	└─sda4   8:4    0 555.5G  0 part /
	sdb      8:16   0   1.1T  0 disk 
	sdc      8:32   0   1.1T  0 disk 
	sdd      8:48   0   1.1T  0 disk 
	sr0     11:0    1  1024M  0 rom  
	[root@r83x6u16 ~]# 


	parted -l
	Model: IBM ServeRAID M5015 (scsi)
	Disk /dev/sda: 599GB
	Sector size (logical/physical): 512B/512B
	Partition Table: gpt
	Disk Flags: 

	Number  Start   End     Size    File system     Name                  Flags
 	1      1049kB  211MB   210MB   fat16           EFI System Partition  boot
 	2      211MB   473MB   262MB   xfs
 	3      473MB   2570MB  2097MB  linux-swap(v1)
 	4      2570MB  599GB   596GB   xfs


	Model: IBM ServeRAID M5015 (scsi)                                         
	Disk /dev/sdb: 1198GB
	Sector size (logical/physical): 512B/512B
	Partition Table: unknown
	Disk Flags: 

	Model: IBM ServeRAID M5015 (scsi)                                         
	Disk /dev/sdc: 1198GB
	Sector size (logical/physical): 512B/512B
	Partition Table: unknown
	Disk Flags: 

	Model: IBM ServeRAID M5015 (scsi)                                         
	Disk /dev/sdd: 1198GB
	Sector size (logical/physical): 512B/512B
	Partition Table: unknown
	Disk Flags: 


Partition
Generally create 2 partitions in each of RAID0, which means 2 partitions are created in /dev/sd[c,d,e]
	
	[root@r83x6u16 yum.repos.d]# parted /dev/sdc
	GNU Parted 3.1
	Using /dev/sdc
	Welcome to GNU Parted! Type 'help' to view a list of commands.
	(parted) mklabel
	New disk label type? gpt                                                  
	(parted) mkpart primary 0 10GB                                            
	Warning: The resulting partition is not properly aligned for best performance.
	Ignore/Cancel? Ignore
	(parted) mkpart primary 10GB -1s
	Warning: You requested a partition from 10.0GB to 1198GB (sectors 19531250..2339839999).
	The closest location we can manage is 10.0GB to 1198GB (sectors 19531251..2339839966).
	Is this still acceptable to you?
	Yes/No? Yes                                                               
	Warning: The resulting partition is not properly aligned for best performance.
	Ignore/Cancel? Ignore                                                     
	(parted) print                                                            
	Model: IBM ServeRAID M5015 (scsi)
	Disk /dev/sdd: 1198GB
	Sector size (logical/physical): 512B/512B
	Partition Table: gpt
	Disk Flags: 

	Number  Start   End     Size     File system  Name     Flags
 	1      17.4kB  10.0GB  10000MB               primary
 	2      10.0GB  1198GB  1188GB                primary
				
List block device after partition is done

	[root@r83x6u16 yum.repos.d]# lsblk
	NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
	sda      8:0    0 557.9G  0 disk 
	├─sda1   8:1    0   200M  0 part /boot/efi
	├─sda2   8:2    0   250M  0 part /boot
	├─sda3   8:3    0     2G  0 part [SWAP]
	└─sda4   8:4    0 555.5G  0 part /
	sdb      8:16   0   1.1T  0 disk 
	├─sdb1   8:17   0   9.3G  0 part 
	└─sdb2   8:18   0   1.1T  0 part 
	sdc      8:32   0   1.1T  0 disk 
	├─sdc1   8:33   0   9.3G  0 part 
	└─sdc2   8:34   0   1.1T  0 part 
	sdd      8:48   0   1.1T  0 disk 
	├─sdd1   8:49   0   9.3G  0 part 
	└─sdd2   8:50   0   1.1T  0 part 

Parted list AFTER partitioning is finished

	[root@r83x6u16 network-scripts]# parted -l
	Model: IBM ServeRAID M5015 (scsi)
	Disk /dev/sda: 599GB
	Sector size (logical/physical): 512B/512B
	Partition Table: gpt
	Disk Flags: 

	Number  Start   End     Size    File system     Name                  Flags
 	1      1049kB  211MB   210MB   fat16           EFI System Partition  boot
 	2      211MB   473MB   262MB   xfs
 	3      473MB   2570MB  2097MB  linux-swap(v1)
 	4      2570MB  599GB   596GB   xfs


	Model: IBM ServeRAID M5015 (scsi)
	Disk /dev/sdb: 1198GB
	Sector size (logical/physical): 512B/512B
	Partition Table: gpt
	Disk Flags: 

	Number  Start   End     Size     File system  Name     Flags
 	1      17.4kB  10.0GB  10000MB               primary
 	2      10.0GB  1198GB  1188GB   xfs          primary


	Model: IBM ServeRAID M5015 (scsi)
	Disk /dev/sdc: 1198GB
	Sector size (logical/physical): 512B/512B
	Partition Table: gpt
	Disk Flags: 
	
	Number  Start   End     Size     File system  Name     Flags
 	1      17.4kB  10.0GB  10000MB               primary
 	2      10.0GB  1198GB  1188GB                primary
	
	
	Model: IBM ServeRAID M5015 (scsi)
	Disk /dev/sdd: 1198GB
	Sector size (logical/physical): 512B/512B
	Partition Table: gpt
	Disk Flags: 
	
	Number  Start   End     Size     File system  Name     Flags
 	1      17.4kB  10.0GB  10000MB               primary
 	2      10.0GB  1198GB  1188GB                primary

## Create [Ceph Configure File](samples/ceph/ceph.conf)

