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
