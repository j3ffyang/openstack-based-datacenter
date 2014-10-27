## Sync /etc/hosts

	for i in 172.16.0.{33..35}; do scp /opt/git/mustang/samples/hosts/hosts $i:/etc/; done

## Update Cookbook
[Roles](samples/cookbooks/chef-repo/roles)        

[Environments](samples/cookbooks/chef-repo/environments/gemini.json)        

[erb](samples/cookbooks/erb/gemini.erb)        

## Deploy Galera

Log into root@chef:/opt/git/gemini/scripts. The script is located at [deploy_controller.sh](samples/cookbooks/scripts/deploy_controller.sh)

	./deploy_controller.sh

## Update root privilege through virtual IP (vIP= 37)

	mysql -u mysql -p password -h localhost
	update user set host='%' where host='localhost';
	flush priviledges;

## Verify Cluster Status


	MySQL [mysql]> SHOW STATUS LIKE 'wsrep%';
	
	| wsrep_incoming_addresses     | 172.16.0.33:3306,172.16.0.34:3306,172.16.0.35:3306 |
	| wsrep_cluster_conf_id        | 3                                                  |
	| wsrep_cluster_size           | 3                                                  |
	| wsrep_cluster_state_uuid     | b92c5f2d-4f06-11e4-b67f-6bd64695ed88               |
	| wsrep_cluster_status         | Primary                                            |
	| wsrep_connected              | ON                                                 |
	| wsrep_local_bf_aborts        | 0                                                  |
	| wsrep_local_index            | 0                                                  |
	| wsrep_provider_name          | Galera                                             |
	| wsrep_provider_vendor        | Codership Oy <info@codership.com>                  |
	| wsrep_provider_version       | 3.5(rXXXX)                                         |
	| wsrep_ready                  | ON                                                 |
	+------------------------------+----------------------------------------------------+
	47 rows in set (0.00 sec)
	
## Modify 1st MySQL node /etc/my.cnf after Cluster Created

	# Group communication system handle
	#wsrep_cluster_address=gcomm://
	wsrep_cluster_address=gcomm://172.16.0.33:4567,172.16.0.34:4567,172.16.0.35:4567
	
