#
# Cookbook Name:: yum
# Recipe:: openstack
#
# Setup OpenStack packages

yum_repository "openstack" do
  description "OpenStack"
  url node['yum']['openstacknoarch']['url']
  action platform?('amazon') ? [:add, :update] : :add
end

yum_repository "openstack-x86-64" do
  description "OpenStack x86-64"
  url node['yum']['openstackx86_64']['url']
  action platform?('amazon') ? [:add, :update] : :add
end
