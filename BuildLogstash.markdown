## Launch VM

## Set hostname

	hostnamectl set-hostname logstash

## Assign IP address, referring to [IP Planning](IPPlanning.markdown)

## Update [/etc/hosts](samples/hosts/hosts)

Log into Chef, then

	cp samples/hosts/hosts /etc/hosts
	for i in `cat /etc/hosts | awk '{print $1}' | grep "172"`; do scp /etc/hosts $i:/etc/hosts; done 
