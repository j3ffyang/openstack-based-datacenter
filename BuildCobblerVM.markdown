## Launch a CentOS 7 VM

## Configure network according [IP Planning](IPPlanning.markdown)
Configuration details
	[root@localhost network-scripts]# pwd
	/etc/sysconfig/network-scripts

	[root@localhost network-scripts]# cat ifcfg-eth0
	TYPE=Ethernet
	BOOTPROTO=none
	IPADDR0=172.16.0.31
	PREFIX0=16
	DEFROUTE=yes
	IPV4_FAILURE_FATAL=no
	IPV6INIT=no
	NAME=eth0
	UUID=f4795324-fa7f-4475-8d03-c11d572a83d4
	DEVICE=eth0
	ONBOOT=yes

	[root@localhost network-scripts]# cat ifcfg-eth1
	TYPE=Ethernet
	BOOTPROTO=none
	IPADDR0=172.29.83.248
	PREFIX0=16
	DEFROUTE=yes
	IPV4_FAILURE_FATAL=no
	IPV6INIT=no
	NAME=eth1
	UUID=2533e32f-5237-45d5-abc8-b549fa1fa6e7
	DEVICE=eth1
	ONBOOT=yes
