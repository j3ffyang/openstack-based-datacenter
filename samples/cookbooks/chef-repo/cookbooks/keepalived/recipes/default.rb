#
# Cookbook Name:: keepalived
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package "keepalived"

if node['keepalived']['shared_address']
  #file '/etc/sysctl.d/60-ip-nonlocal-bind.conf' do
  #file '/etc/sysctl.conf' do
  #  mode 0644
  #  content "net.ipv4.ip_nonlocal_bind = 1\n"
  #end

  #service 'procps' do
  #  action :start
  #end

  #bash "reload-sysctl" do
  #  code <<-EOH
  #    if [ -z "$(cat /etc/sysctl.conf | grep net.ipv4.ip_nonlocal_bind)" ];then
  #      echo "net.ipv4.ip_nonlocal_bind = 1" >> /etc/sysctl.conf
  #      sysctl -p > /dev/null 2>&1
  #    fi
  #  EOH
  #end

  #execute 'Check db2 node hostname' do
  #    command 'echo "net.ipv4.ip_nonlocal_bind = 1" >> /etc/sysctl.conf'
  #    not_if 'grep net.ipv4.ip_nonlocal_bind /etc/sysctl.conf)'
  #end

end

template "keepalived.conf" do
  path "/etc/keepalived/keepalived.conf"
  source "keepalived.conf.erb"
  owner "root"
  group "root"
  mode 0644
end

service "keepalived" do
  supports :restart => true
  action [:enable, :start]
  subscribes :restart, "template[keepalived.conf]"
end
