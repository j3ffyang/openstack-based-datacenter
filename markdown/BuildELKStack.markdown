## Log Monitoring

## ELK (Elasticsearch, Logstash, Kibana) Stack Overview
![ELK Overview](/images/20141202_file_logstash_es_kibana.png)

Reference: [http://www.elasticsearch.org/overview/](http://www.elasticsearch.org/overview/)

Note: Above is a very high level overview, to improve the scalability we can adopt the following structure, the redis broker could be replaced by any others candidate, such as Kafka:

![Centralized ELK Overview](/images/20141202_advanced_elk.png)

## Install Elasticsearch on CentOS 7
You need install the ruby before the steps in below since it is prereqed by Elasticsearch.

Ensure the local host name is resolvable (you can add the local host name and ip address into the [/etc/hosts](/samples/hosts/hosts)).

Update iptables rule, the IP_ADRRESS_1,IP_ADRRESS_2,IP_ADRRESS_3 are the IP address of ES (Elasticsearch) cluster nodes you plan to install ES:

	iptables -I INPUT 1 -p tcp --dport 9300:9400 -j REJECT
	iptables -I INPUT 1 -m pkttype --pkt-type multicast -j ACCEPT
	iptables -I INPUT 1 -p tcp --dport 9200 -j ACCEPT
	iptables -I INPUT 1 -p tcp --dport 9300:9400 -s IP_ADRRESS_1,IP_ADRRESS_2,IP_ADRRESS_3 -j ACCEPT

	iptables-save > /etc/sysconfig/iptables.rules    
	echo '/sbin/iptables-restore < /etc/sysconfig/iptables.rules' >> /etc/rc.d/rc.local    
	chmod +x /etc/rc.d/rc.local    

Ensure the ntp sync is enabled.

The elasticsearch cookbook can be found on chef server (9.110.178.26), use following command to install elasticsearch:

	chef-client -N elasticsearch

Use following command to check the ES cluster status

	curl http://IP_ADDRESS_1:9200/_cluster/health    
	curl http://IP_ADDRESS_1:9200/?pretty

You can find the existing elasticsearch nodes in [IP Planning](IPPlanning.markdown)

## Install Logstash on CentOS 7
The logstash cookbook can be found on chef server (9.110.178.26), use following command to install logstash:

You need to create a new node named logstash-control-ctrlr1 (on ctrl1), second to the 1st logstash-control (on ctrlr0)

	chef-client -N logstash-control-ctrlr1 -S https://chef:443 -K /etc/chef/chef-validator.pem

Then 

	/etc/init.d/logstanh-agent restart

On Compute node

	chef-client -N logstash-compute

There are different logstash input files for each logstash related chef role, you need update the filter or create a new role if you want to monitor new log files.

If you have different filter logic (grok, filter, codec, muate and etc), you can customize the 'templates/default/openstack-logstash-filter.conf.erb' in logstash cookbook or create new template.


## Install Kibana on CentOS 7

Enable the iptables firewall:    

	iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT    
	iptables-save > /etc/sysconfig/iptables.rules    
	echo '/sbin/iptables-restore < /etc/sysconfig/iptables.rules' >> /etc/rc.d/rc.local    
	chmod +x /etc/rc.d/rc.local    

The kibana cookbook can be found on chef server (9.110.178.26), use following command to install kibana

	chef-client -N kibana

In mustang, the nginx proxy of the kibana is enabled on the 9.110.178.27, you can access the Kibana dashboard via 'http://9.110.178.27/kibana/'
