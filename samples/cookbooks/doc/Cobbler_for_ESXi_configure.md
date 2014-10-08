How to configure cobbler to install ESXi system from PXE
==

Step 1. Prepare ESXi ISO for cobbler.

    mount -o loop ESXi-5.5.0-1331820-IBM-20131115.iso /mnt/
    cobbler import --name ESXi-5.5.0-1331820-IBM --path /mnt/

Note : You may find the following errors:

    # cobbler import --name ESXi-5.5.0-1331820-IBM --path /mnt/

    task started: 2014-04-14_204537_import
    task started (id=Media import, time=Mon Apr 14 20:45:37 2014)
    Found a candidate signature: breed=vmware, version=esxi51
    running: /usr/bin/file /var/www/cobbler/ks_mirror/ESXi-5.5.0-1331820-IBM/s.v00

    received on stdout: /var/www/cobbler/ks_mirror/ESXi-5.5.0-1331820-IBM/s.v00: gzip compressed data, was "vmvisor-sys.tar.vtar", from Unix, last modified: Thu Sep 19 02:39:27 2013

    received on stderr: 
    Found a candidate signature: breed=vmware, version=esxi5
    running: /usr/bin/file /var/www/cobbler/ks_mirror/ESXi-5.5.0-1331820-IBM/s.v00

    received on stdout: /var/www/cobbler/ks_mirror/ESXi-5.5.0-1331820-IBM/s.v00: gzip compressed data, was "vmvisor-sys.tar.vtar", from Unix, last modified: Thu Sep 19 02:39:27 2013

    received on stderr: 
    No signature matched in /var/www/cobbler/ks_mirror/ESXi-5.5.0-1331820-IBM
    !!! TASK FAILED !!!

> The workaround is below:

 - 1.back up distro_signatures.json file .


    cd /var/lib/cobbler/
    cp distro_signatures.json distro_signatures.json.bak

 - 2.Modify ESXi 5.1 to 5.5 .


    "version_file_regex":"^.*ESXi 5\\.1\\.(.*)build-([\\d]+).*$",
    to 
    "version_file_regex":"^.*ESXi 5\\.5\\.(.*)build-([\\d]+).*$",

 - 3.Restart cobbler service.


    # /etc/init.d/cobblerd restart
    Stopping cobbler daemon:                                   [  OK  ]
    Starting cobbler daemon:                                   [  OK  ]

 - 4.Retry 'cobbler import --name ESXi-5.5.0-1331820-IBM --path /mnt/'.

Step 2. Define two profile templates in the cobbler:

    /etc/cobbler/pxe/pxeprofile_esxi.template:

    default linux

    prompt 0

    timeout 1

    label linux

    kernel $kernel_path

    ipappend 2

    append -c $img_path/boot.cfg append $img_path/vmkboot.gz $append_line  --- $img_path/vmkernel.gz --- $img_path/sys.vgz --- $img_path/cim.vgz  --- $img_path/ienviron.vgz --- $img_path/install.vgz

    /etc/cobbler/pxe/pxesystem_esxi.template:

    default linux

    prompt 0

    timeout 1

    label linux

    kernel $kernel_path

    ipappend 2

    append -c $img_path/boot.cfg append $img_path/vmkboot.gz $append_line --- $img_path/vmkernel.gz --- $img_path/sys.vgz --- $img_path/cim.vgz --- $img_path/ienviron.vgz --- $img_path/install.vgz

>This should affect boot.cfg and mac address profiles content.

Step 3. Use 'cobbler profile report  ESXi-5.5.0-1331820-IBM' to get kickstarts path:

     Kickstart                      : /var/lib/cobbler/kickstarts/sample_esxi5.ks
     
Step 4. Modify kickstart file in /var/lib/cobbler/kickstarts/sample_esxi5.ks :

    # sample Kickstart for ESXi

    accepteula
    # Set the root password for the DCUI and ESXi Shell
    rootpw passw0rd

    # Install on the first local disk available on machine
    install --firstdisk --overwritevmfs

    # Set the network to DHCP on the first network adapater, use the specified hostname and do not create a portgroup for the VMs
    network --bootproto=dhcp --device=vmnic0 --addvmportgroup=0

    #reboot machine
    reboot

    $SNIPPET('kickstart_start')
    $SNIPPET('kickstart_done')

Step 5. Replace boot.cfg file  '/' to '' :

    sed -i 's@/@@g' /var/www/cobbler/ks_mirror/ESXi-5.5.0-1331820-IBM/boot.cfg

Step 6. Execute 'cobbler sync' 
* Double check '/var/lib/tftpboot/images/ESXi-5.5.0-1331820-IBM-x86_64/*' whether is nil , If no files ther, then you need to copy files manually, for exmaple:


    cp /var/www/cobbler/ks_mirror/VMware-VMvisor-5.1/*.* /var/lib/tftpboot/images/VMware-VMvisor-5.1-x86_64/

How to use asu tools to remote control IMM configuration:
----

step 1. Get physical machine hardware information:

    /iaas/gemini/asu/asu64 show all --host 172.29.26.35 --user USERID --password PASSW0RD

step 2. Change the boot order：

    /iaas/gemini/asu/asu64 set BootOrder.BootOrder "PXE Network=CD/DVD Rom=Legacy Only=Hard Disk 0" --host 172.29.26.35 --user USERID --password PASSW0RD

step 3. Change nic PXE mode:

    /iaas/gemini/asu/asu64 set PXE.NicPortPxeMode.1 "Legacy Support" --host 172.29.26.35 --user USERID --password PASSW0RD

step 4. Add a new machine in the cobbler system:

    cobbler system add --name=R26-M4-35 --profile=ESXi-5.5.0-1331820-IBM-x86_64 --interface=eth0 --mac=6C:AE:8B:51:29:E2 --ip-address=172.16.26.35 --netmask=255.255.255.0 --gateway=172.16.26.1 --hostname=R26-M4-35 --power-type=imm --power-address=172.29.26.35 --power-user=USERID --power-pass=PASSW0RD --server=172.16.27.199

step 5. Configure next boot order:

    cobbler system edit --name=R26-M4-35 --netboot-enabled=1

    cobbler sync

step 6: Reboot the system remotely

    cobbler system reboot --name=R26-M4-35

