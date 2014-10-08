## Sync /etc/hosts

	for i in 172.16.0.{33..35}; do scp /opt/git/mustang/samples/hosts/hosts $i:/etc/; done

## Update Cookbook
