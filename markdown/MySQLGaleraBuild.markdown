

yum install perl-Data-Dumper chef libaio rsync net-tools -y

mkdir -p /etc/chef/; cd /etc/chef/

echo "9.110.178.26 chef" >> /etc/hosts

scp chef:/etc/chef-server/validation.pem /etc/chef/
scp chef:/etc/chef-server/knife.rb /etc/chef/

chef-client -c /etc/chef/knife.rb -r 'role[galera-cluster]'

uncomments the "wsrep_node_incoming_address=10.100.100.18" in /etc/my.conf and restart mysql service

