## Sync /etc/hosts

	for i in 172.16.0.{33..35}; do scp /opt/git/mustang/samples/hosts/hosts $i:/etc/; done

## Update Cookbook
[Roles](samples/cookbooks/chef-repo/roles)        

[Environments](samples/cookbooks/chef-repo/environments/gemini.json)        

[erb](samples/cookbooks/erb/gemini.erb)        
