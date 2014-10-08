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

