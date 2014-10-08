#!/bin/bash

# Setuping configurations
EPEL_REPO_RPM_URL=http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RABBITMQ_SERVER_PKG_URL=http://www.rabbitmq.com/releases/rabbitmq-server/v3.3.1/rabbitmq-server-3.3.1-1.noarch.rpm
RABBITMQ_CLUSTER_CFG_FILE=/etc/rabbitmq/rabbitmq_cluster.config

http_proxy=http://172.16.27.100:8085/
https_proxy=http://172.16.27.100:8085/

# Verifying inputs
if [ $# -lt 2 ]; then
    echo "Usage: $0 <HOST1> [HOST2] [HOSTN] <ERLANG_COOKIE>"
    exit 1
fi

rabbitmq_hosts=${@:1:$#-1}
for host in $rabbitmq_hosts; do
    cat /etc/hosts | grep -v "^#" | grep -v "^;" | grep "\s$host\s*$" > /dev/null 2>&1
    if [ $? -gt 0 ]; then
        echo "Error: Host $host doesn't exist in your /etc/hosts file."
        exit 1
    fi
done

# Installing Erlang environment
curl $EPEL_REPO_RPM_URL > /tmp/epel-release.noarch.rpm 2> /dev/null
rpm -Uvh /tmp/epel-release.noarch.rpm > /dev/null
rm -f /tmp/epel-release.noarch.rpm > /dev/null
yum -y install erlang > /dev/null

# Installing Rabbitmq server package
curl $RABBITMQ_SERVER_PKG_URL > /tmp/rabbitmq-server.noarch.rpm 2> /dev/null
rpm --import http://www.rabbitmq.com/rabbitmq-signing-key-public.asc > /dev/null
yum -y install /tmp/rabbitmq-server.noarch.rpm > /dev/null
rm -f /tmp/rabbitmq-server.noarch.rpm > /dev/null

# Configuring Rabbitmq server automatic startup
chkconfig rabbitmq-server on > /dev/null

# Generating Rabbitmq cluster configuration file
node_list=()
for host in $rabbitmq_hosts; do
   node_list+=("'rabbit@$host'")
done
node_str=$( IFS=$','; echo "${node_list[*]}" )
echo '[{rabbit, [{cluster_nodes, {['$node_str'], disc}}]}]' > $RABBITMQ_CLUSTER_CFG_FILE

# Updating Erlang cookie
erlange_cookie=${!#}
echo $erlange_cookie > /var/lib/rabbitmq/.erlang.cookie
chmod 400 /var/lib/rabbitmq/.erlang.cookie
chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie

# To launch Rabbitmq server
service rabbitmq-server restart > /dev/null

# Updating Rabbitmq to use mirror queue
rabbitmqctl set_policy ha-all "^" '{"ha-mode":"all"}' > /dev/null

# Showing cluster status out
rabbitmqctl cluster_status
