## Setup NTP
Do the following steps on Chef server

	ssh -t root@172.16.0.201 "yum install ntp -y"

	[root@chef mustang]# scp /opt/git/mustung/samples/ntp/ntp.conf 172.16.0.201:/etc/
	root@172.16.0.201's password: 
	ntp.conf                                                                            100% 2044     2.0KB/s   00:00    
	[root@chef mustang]# ssh -t root@172.16.0.201 "systemctl enable ntpd"
	root@172.16.0.201's password: 
	ln -s '/usr/lib/systemd/system/ntpd.service' '/etc/systemd/system/multi-user.target.wants/ntpd.service'
	Connection to 172.16.0.201 closed.
	[root@chef mustang]# ssh -t root@172.16.0.201 "systemctl start ntpd"
	root@172.16.0.201's password: 
	Connection to 172.16.0.201 closed.
	[root@chef mustang]# scp ./samples/ntp/ntp.conf 172.16.0.202:/etc/
	root@172.16.0.202's password: 
	ntp.conf                                                                            100% 2044     2.0KB/s   00:00    
	ssh -t root@172.16.0.201 "ntpdate -u 9.117.78.100"
