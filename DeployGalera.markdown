## Sync /etc/hosts

	for i in 172.16.0.{33..35}; do scp /opt/git/mustang/samples/hosts/hosts $i:/etc/; done

## Update Cookbook
The cookbook is referenced from our another development and test environment, which is called "Gemini". We just didn't change its name and use it as it is.
[Roles](samples/cookbooks/chef-repo/roles)        

[Environments](samples/cookbooks/chef-repo/environments/gemini.json)        

[erb](samples/cookbooks/erb/gemini.erb)        

## Deploy Galera

Log into root@chef:/opt/git/gemini/scripts

	./deploy_controller.sh

## Update root privilege

	mysql -u mysql -p password -h localhost
	update user set host='%' where host='localhost';
	flush priviledges;
