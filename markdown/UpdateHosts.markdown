## Update Hosts
Login Chef server. Pull all cookbook. Then update [/etc/hosts](samples/hosts/hosts)

	for i in `cat hosts | awk '{print $1}' | grep "172"`; do scp hosts $i:/etc/hosts; done
