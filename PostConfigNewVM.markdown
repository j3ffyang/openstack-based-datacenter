## Launch VM

Refer to [build a VM](BuildAnImage.markdown)

## Set hostname

	hostnamectl set-hostname logstash

## Assign IP address, referring to [IP Planning](IPPlanning.markdown)

## Add SSH key

	ssh-copy-id root@logstash

## Update [/etc/hosts](samples/hosts/hosts)

Log into Chef, then

	cp samples/hosts/hosts /etc/hosts
	for i in `cat /etc/hosts | awk '{print $1}' | grep "172"`; do scp /etc/hosts $i:/etc/hosts; done 

## Update /etc/yum.repos.d/

Log into Chef, then

	ssh root@logstash "mv /etc/yum.repos.d/CentOS*.repo /tmp/"; scp /opt/git/mustang/samples/yum_repos_d/*.repo root@logstash:/etc/yum.repos.d/

## Install NTP

Log into Chef, then

	ssh logstash "yum install ntp -y"; scp /opt/git/mustang/samples/ntp/ntp.conf logstash:/etc/
	ssh logstash "systemctl enable ntpd"; ssh logstash "systemctl restart ntpd"; ssh logstash "ntpdate -u 172.16.0.22"
