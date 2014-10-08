#
# Cookbook Name:: dnsconfig
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

template "/var/named/forward.db" do
  source "forward.db.erb"
end

service "named" do
  action [ :enable, :restart ]
end

