## Install CentOS 7 x86_64
According to Controller's [partition layout](./DiskConfiguration)

## Update Hostname
    [root@localhost ~]# hostnamectl set-hostname r83x5u09

## Configure NICs
    [root@r83x5u09 network-scripts]# cat ifcfg-br0
    DEVICE=br0
    STP=yes
    BRIDGING_OPTS=priority=32768
    TYPE=Bridge
    BOOTPROTO=none
    IPADDR0=172.16.0.21
    PREFIX0=16
    DEFROUTE=yes
    IPV4_FAILURE_FATAL=no
    IPV6INIT=no
    NAME=br0
    UUID=73f81e3f-0064-4f91-8186-6a049dce646a
    ONBOOT=no

    [root@r83x5u09 network-scripts]# cat ifcfg-br1
    DEVICE=br1
    STP=yes
    BRIDGING_OPTS=priority=32768
    TYPE=Bridge
    BOOTPROTO=none
    IPADDR0=9.110.178.28
    PREFIX0=24
    GATEWAY0=9.110.178.1
    DNS1=9.0.146.50
    DNS2=9.0.148.50
    DEFROUTE=yes
    IPV4_FAILURE_FATAL=no
    IPV6INIT=no
    NAME=br1
    UUID=56e7b322-53b6-4b73-861c-829533c1757e
    ONBOOT=no

    [root@r83x5u09 network-scripts]# cat ifcfg-br2
    DEVICE=br2
    STP=yes
    BRIDGING_OPTS=priority=32768
    TYPE=Bridge
    BOOTPROTO=none
    IPADDR0=172.29.83.249
    PREFIX0=16
    DEFROUTE=yes
    IPV4_FAILURE_FATAL=no
    IPV6INIT=no
    NAME=br2
    UUID=549ed8aa-415a-4701-ba7e-e377b7c886e0
    ONBOOT=no

    [root@r83x5u09 network-scripts]# cat ifcfg-eno1 
    TYPE=Ethernet
    NAME=eno1
    UUID=3a9cf49c-ee2a-4b87-bb74-d2774102a9b9
    DEVICE=eno1
    ONBOOT=yes
    BRIDGE=73f81e3f-0064-4f91-8186-6a049dce646a

    [root@r83x5u09 network-scripts]# cat ifcfg-eno2
    TYPE=Ethernet
    NAME=eno2
    UUID=391707fd-7582-4d60-9e86-1ee541945b1f
    DEVICE=eno2
    ONBOOT=yes
    BRIDGE=56e7b322-53b6-4b73-861c-829533c1757e

    [root@r83x5u09 network-scripts]# cat ifcfg-ens3f1 
    TYPE=Ethernet
    NAME=ens3f1
    UUID=1fdac1f9-6332-49ba-b247-65a31460b4f9
    DEVICE=ens3f1
    ONBOOT=yes
    BRIDGE=549ed8aa-415a-4701-ba7e-e377b7c886e0

## Bridge
    [root@r83x5u09 network-scripts]# brctl show
    bridge name	bridge id		STP enabled	interfaces
    br0		8000.3440b59f6214	yes		eno1
    br1		8000.3440b59f6216	yes		eno2
    br2		8000.001018ccfa6d	yes		ens3f1
    virbr0		8000.000000000000	yes		

    [root@r83x5u09 network-scripts]# nmcli dev status
    DEVICE       TYPE      STATE                                  CONNECTION         
    br0          bridge    connected                              br0                
    br1          bridge    connected                              br1                
    br2          bridge    connected                              br2                
    eno1         ethernet  connected                              eno1               
    eno2         ethernet  connected                              eno2               
    enp0s29f0u2  ethernet  connected                              Wired connection 1 
    ens3f1       ethernet  connected                              ens3f1             
    virbr0       bridge    connecting (getting IP configuration)  virbr0             
    ens3f0       ethernet  unavailable                            --                 
    lo           loopback  unmanaged                              --                 

    [root@r83x5u09 network-scripts]# nmcli con show
    NAME    UUID                                  TYPE            DEVICE 
    eno1    3a9cf49c-ee2a-4b87-bb74-d2774102a9b9  802-3-ethernet  eno1   
    eno2    391707fd-7582-4d60-9e86-1ee541945b1f  802-3-ethernet  eno2   
    ens3f1  1fdac1f9-6332-49ba-b247-65a31460b4f9  802-3-ethernet  ens3f1 
    br0     73f81e3f-0064-4f91-8186-6a049dce646a  bridge          br0    
    br1     56e7b322-53b6-4b73-861c-829533c1757e  bridge          br1    
    br2     549ed8aa-415a-4701-ba7e-e377b7c886e0  bridge          br2    
    virbr0  8af18cb5-e2c0-452e-840a-776092df36b2  bridge          virbr0 
    [root@r83x5u09 network-scripts]# 


## Specify Default Routing. Edit /etc/sysconfig/network-scripts/ifup-post (optional)
	ip route del default
	ip route add 9.0.0.0/8 via 9.110.178.1 dev eno2
	ip route add 172.16.0.0/16 via 172.16.0.10 dev eno1

	brctl addif eno2 br1

## Enable postrouting by IPTables (important)
	iptables -t nat -A POSTROUTING -s 172.16.0.0/16 -j MASQUERADE
	iptables -L -n -v
	iptables -t nat -L

## Restart network service
	systemctl restart network.service

## Other packages to install
	xauth qemu-kvm qemu-kvm-tools qemu-kvm-common virt-manager

## Disable SELinux
	setenforce 0
	sestatus
