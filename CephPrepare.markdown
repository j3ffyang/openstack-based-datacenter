## Update Hostname from Chef Server, according to [IP Planning](IPPlanning.markdown)
Pull git code first
	
	cd /opt/git/; git pull
	ssh -t root@172.16.0.201 "hostnamectl set-homename r83x6u16"

## Configure Yum Repo
Running the following command from Chef server
	
	scp /opt/git/mustang/samples/yum_repos_d/*.repo 172.16.0.36:/etc/yum.repos.d/

## Sync [/etc/hosts](samples/hosts/)

	scp /opt/git/mustang/samples/hosts/hosts 172.16.0.36:/etc/

## Network Configuration. Sample on r83x6u16 (172.16.0.201)
Use fiber NIC

	[root@r83x6u16 network-scripts]# ethtool ens2f0
	Settings for ens2f0:
		Supported ports: [ FIBRE ]
		Supported link modes:   Not reported
		Supported pause frame use: Symmetric
		Supports auto-negotiation: No
		Advertised link modes:  Not reported
		Advertised pause frame use: No
		Advertised auto-negotiation: No
		Speed: 10000Mb/s
		Duplex: Full
		Port: FIBRE
		PHYAD: 0
		Transceiver: external
		Auto-negotiation: off
		Supports Wake-on: d
		Wake-on: d
		Current message level: 0x00002000 (8192)
			       	hw
		Link detected: yes
	[root@r83x6u16 network-scripts]# ethtool ens2f1
	Settings for ens2f1:
		Supported ports: [ FIBRE ]
		Supported link modes:   Not reported
		Supported pause frame use: Symmetric
		Supports auto-negotiation: No
		Advertised link modes:  Not reported
		Advertised pause frame use: No
		Advertised auto-negotiation: No
		Speed: 10000Mb/s
		Duplex: Full
		Port: FIBRE
		PHYAD: 1
		Transceiver: external
		Auto-negotiation: off
		Supports Wake-on: d
		Wake-on: d
		Current message level: 0x00002000 (8192)
			       	hw
		Link detected: yes

The 1st fiber network card, used for link to VM

	[root@r83x6u16 network-scripts]# ip addr show ens2f0
	8: ens2f0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP qlen 1000
	    link/ether 00:00:c9:cd:a2:1c brd ff:ff:ff:ff:ff:ff
	    inet 172.18.0.201/16 brd 172.18.255.255 scope global ens2f0
	       valid_lft forever preferred_lft forever
    	inet6 fe80::200:c9ff:fecd:a21c/64 scope link 
       	       valid_lft forever preferred_lft forever

The 2nd fiber network card, used for Ceph storage traffic

	[root@r83x6u16 network-scripts]# ip addr show ens2f1
	10: ens2f1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP qlen 1000
	    link/ether 00:00:c9:cd:a2:20 brd ff:ff:ff:ff:ff:ff
    	    inet 172.17.0.201/16 brd 172.17.255.255 scope global ens2f1
       	       valid_lft forever preferred_lft forever
            inet6 fe80::200:c9ff:fecd:a220/64 scope link 
               valid_lft forever preferred_lft forever
	[root@r83x6u16 network-scripts]# 

