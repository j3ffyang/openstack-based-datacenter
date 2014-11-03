## Setup NTP
Do the following steps on Chef server

	ssh -t root@172.16.0.201 "yum install ntp -y"

	[root@chef mustang]# scp /opt/git/mustang/samples/ntp/ntp.conf 172.16.0.201:/etc/
	root@172.16.0.201's password: 
	ntp.conf                                                                            100% 2044     2.0KB/s   00:00    

## Sync SSH Key (run on Chef)

	for i in `cat /etc/hosts | awk '{print $1}' | grep 172`; do ssh-copy-id root@$i; done

## Enable All NTP client (running the cmd on Chef)

	for i in `cat /etc/hosts | grep 172 | grep -v '172.16.0.20\|172.16.0.22' | grep -v chef`; do echo $i; scp /etc/ntp.conf $i:/etc/; ssh $i "systemctl stop ntpd; ntpdate -u 172.16.0.22; systemctl enable ntpd; systemctl start ntpd"; done

20 = 201, 202, 203... all Ceph hosts. They're already sync'd. Be careful when running ntpdate which could break their own sync
22 = Chef server, which is running on CentOS65. The only 65 in env.
