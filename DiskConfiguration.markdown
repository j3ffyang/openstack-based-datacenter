## Disk Configuration
At our data center, each node has 600G*8 disks.

## Controller Node

r83x5u08 - all 4 disks configured in RAID1

| Label | Size |
| ----- | ---- |
| /boot | 250M |
| /boot/efi | 250M |
| / | 100G |
| /var/log | 20G |
| /var | remaining space |

r83x5u09

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
