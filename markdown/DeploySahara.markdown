## Launch a VM on Controller Host

Refer to [launch a VM](PostConfigNewVM.markdown)

## Install and Configure Sahara

Refer to [Sahara with OpenStack](http://docs.openstack.org/developer/sahara/icehouse/userdoc/installation.guide.html)

## Add Sahara into HAProxy

Add the following into each HAProxy nodes /etc/haproxy/haproxy.cfg

	listen openstack-sahara-api
	  bind 0.0.0.0:8386
	  mode http
	  log global
	  balance  source
	  #option httpchk
	  option tcpka
	  server sahara 172.16.0.40:8386 check inter 2000 rise 2 fall 5

Modify etc/openstack-dashboard/local_settings on each Horizon node

	# sahara
	SAHARA_USE_NEUTRON = True
	SAHARA_URL = 'http://172.16.0.37:8386/v1.1'
	#AUTO_ASSIGNMENT_ENABLED = False

Restart HAProxy and Horizon on each of Horizon node

	systemctl restart haproxy
	systemctl restart httpd
