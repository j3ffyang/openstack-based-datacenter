## Install and Basic Configuration

Reference: [http://www.rabbitmq.com/clustering.html](http://www.rabbitmq.com/clustering.html)

Our cookbook installs and configures RabbitMQ on 3 nodes basically. But the 2nd and 3rd nodes didn't start up in cluster properly.

On 1st RabbitMQ node    

	[root@ctrlr0 rabbitmq]# rabbitmq-server --detached
	[root@ctrlr0 rabbitmq]# rabbitmqctl cluster_status
	Cluster status of node rabbit@ctrlr0 ...
	[{nodes,[{disc,[rabbit@ctrlr0]},{ram,[rabbit@ctrlr1]}]},
	 {running_nodes,[rabbit@ctrlr0]},
	 {partitions,[]}]
	...done.

        [root@ctrlr0 ~]# rabbitmqctl stop_app
        Stopping node rabbit@ctrlr0 ...
        ...done.
        [root@ctrlr0 ~]# rabbitmqctl start_app

	
On 2nd and 3rd RabbitMQ node

	[root@ctrlr1 rabbitmq]# rabbitmqctl status
	Status of node rabbit@ctrlr1 ...
	Error: unable to connect to node rabbit@ctrlr1: nodedown
	
	DIAGNOSTICS
	===========
	
	nodes in question: [rabbit@ctrlr1]
	
	hosts, their running nodes and ports:
	- ctrlr1: [{rabbitmqctl11004,60256}]
	
## Stop all Existing Processes and Restart them
Do the following commands on 2nd and 3rd RabbitMQ nodes

	[root@ctrlr1 ~]# sudo -u rabbitmq rabbitmqctl stop
	Stopping and halting node rabbit@ctrlr1 ...
	...done.


or


	[root@ctrlr2 ~]# kill -9 `ps -ef | grep rabbitmq | awk '{print $2}'`
	-bash: kill: (13951) - No such process
	
	[root@ctrlr2 ~]# rabbitmq-server --detached
	
	              RabbitMQ 3.1.5. Copyright (C) 2007-2013 GoPivotal, Inc.
	  ##  ##      Licensed under the MPL.  See http://www.rabbitmq.com/
	  ##  ##
	  ##########  Logs: /var/log/rabbitmq/rabbit@ctrlr2.log
	  ######  ##        /var/log/rabbitmq/rabbit@ctrlr2-sasl.log
	  ##########
	              Starting broker... completed with 7 plugins.
	^Z
	[1]+  Stopped                 rabbitmq-server --detached
	[root@ctrlr2 ~]# bg
	[1]+ rabbitmq-server --detached &
	
	[root@ctrlr2 ~]# rabbitmqctl stop_app
	Stopping node rabbit@ctrlr2 ...
	...done.
	[root@ctrlr2 ~]# rabbitmqctl join_cluster --ram rabbit@ctrlr0
	Clustering node rabbit@ctrlr2 with rabbit@ctrlr0 ...
	...done.
	[root@ctrlr2 ~]# rabbitmqctl start_app
	
## Check the Status

	[root@ctrlr0 rabbitmq]# rabbitmqctl cluster_status
	Cluster status of node rabbit@ctrlr0 ...
	[{nodes,[{disc,[rabbit@ctrlr0]},{ram,[rabbit@ctrlr2,rabbit@ctrlr1]}]},
	 {running_nodes,[rabbit@ctrlr0]},
	 {partitions,[]}]
	...done.
	
## Deploy RabbitMQ Cluster in HAProxy

On 172.16.0.33 (ctrlr0), edit /etc/haproxy/haproxy.cfg

        listen rabbitmq_management
          bind 0.0.0.0:25672
          mode http
          log global
          balance  source
          #option httpchk
          option tcpka
          server ctrlr0 172.16.0.33:15672 check inter 2000 rise 2 fall 5
          server ctrlr1 172.16.0.34:15672 check inter 2000 rise 2 fall 5
          server ctrlr2 172.16.0.35:15672 check inter 2000 rise 2 fall 5

Restart HAProxy

        /etc/init.d/haproxy restart

Repeat the above on 34(ctrlr1)/ 35(ctrlr2)

Access on Web

        http://9.110.178.27/haproxy


## Deploy RabbitMQ Cluster in Nginx

On 9.110.178.27 (management VM host), edit /etc/nginx/nginx.conf

        ...
                }
                location /elasticsearch {
                  proxy_pass http://172.16.0.42:9200/;
                }
                location /rabbitmq/ {
                  proxy_pass http://172.16.0.37:25672/;
        ...

Restart Nginx

        systemctl restart nginx

## Access Management on Web

        http://9.110.178.27/rabbitmq/

