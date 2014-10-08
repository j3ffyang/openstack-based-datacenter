#
# Author:: Salman Baset (sabaset@us.ibm.com)
# Cookbook Name:: yum
# Recipe:: rhel
#

yum_repository "rhel" do
  description "Extra Packages for Enterprise Linux"
  key node['yum']['rhel63']['key']
  url node['yum']['rhel63']['url']
  action platform?('amazon') ? [:add, :update] : :add
end
