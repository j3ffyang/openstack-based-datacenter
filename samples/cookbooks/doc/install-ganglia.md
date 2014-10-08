#the steps for installing ganglia monitor client and server in gemini by cookbook

ganglia is collect the work status of computer node,and report those status to Customer by Web style.
and there are two function module for ganglia. one is ganglia-server(gmetad),the other is ganglia-client(gmond).

Ganglia cookbook had been upload to gemini cloud.
1. when you need you to install ganglia-server on the computer,you need inplement those command below:
chef-client -o ganglia::web
chef-client -o ganglia::graphite
then you can use "telnet localhost 8651" to check ganglia server.
if the command implement is ok,there will be show XML information.else ganglia server can't work 

2. when you need you to install ganglia-client on the computer,you need inplement those command below:
chef-client -o ganglia
also you can user "telnet localhost 8649" to check ganglia client.
if the command implement is ok,there will be show XML information.else ganglia client can't work
