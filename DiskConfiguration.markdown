## Disk Configuration
At our data center, each node has 600G*8 disks.

## Controller Node
   * Two RAID drive groups:
     1. one RAID1 for OS: two disks
     2. one RAID5 for other VMs which run the controller serives: 6 disks
   * Partitions on the RAID1:
     1. /boot 250M
     2. /boot/efi 250M
     3. swap 2G
     4. / given the remaining space
   * Partitions on the RAID5:
     1. /var/lib/libvirt    the whole remaining space on disk

| Label | Size | 
| ----- | ---- |
| /boot | 250M |
| /boot/efi | 250M | 
| SWAP | 2G |
| /    | 200G |
| /var/lib/libvirt | the whole remaining space on disk | 

## Compute Node
   * Two RAID drive groups:
     1. one RAID1 for OS: two disks
     2. one RAID5: 6 disks
   * Partitions on the RAID1:
     1. /boot 250M
     2. swap 2G
     3. / the remaining disk space.
   * Partitions on the RAID5:
     1. /var/lib/nova   the remaining disk space

## Storage Node
  * 7 RAID drive groups:
    1. one RAID1 for OS: two disks
    2. 6 RAID0 for OSDs: each RAID0/OSD per disk
  * Partitions on the RAID1:
    1. /boot 250M
    2. swap  2G
    3. / the remaining disk space.
  * Partitions on the RAID0:
    No need to create the partition. When creating the OSD, just specify which physical disk and file system are used.

## RAID Cache Configuration
   * Strip Size: 128KB
   * Access Policy: RW
   * Write Policy: write back with BBU
   * Read Policy: Normal
   * I/O Policy: cache
   * Drive cache: Disable
   * Disable BGI: No
