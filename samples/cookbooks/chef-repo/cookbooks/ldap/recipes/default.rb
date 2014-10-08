package 'openldap'

caertdir = nil
File.open("/etc/openldap/ldap.conf", "r") do |infile|
    while (line = infile.gets)
        matcher = line.match /^\s*TLS_CACERTDIR\s+(.+)/
        caertdir = matcher[1] unless matcher.nil?
    end
end

log "caertdir=#{caertdir}" do
  level :debug
end

cacertfile_file = File.join(caertdir, node[:ldap][:tls_cacertfile_file])

execute "create TLS_CACERT file" do
  action :run
  command "echo -n | openssl s_client -connect #{node[:ldap][:server]}:#{node[:ldap][:ssl_port]} | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > #{cacertfile_file}"
end

template "#{node[:ldap][:keystone_middleware_dir]}/autopop.py" do
    source "autopop.py"
    mode 0644
end

template "#{node[:ldap][:keystone_middleware_dir]}/ldapauth.py" do
    source "ldapauth.py"
    mode 0644
end

options = [
  ["ldap_pre_auth",   "url",                 "ldap://#{node[:ldap][:server]}"],
  ["ldap_pre_auth",   "user_tree_dn",        node[:ldap][:user_tree_dn]],
  ["ldap_pre_auth",   "user_attribute_name", node[:ldap][:user_attribute_name]],
  ["ldap_pre_auth",   "use_tls",             node[:ldap][:use_tls]],
  ["ldap_pre_auth",   "tls_cacertfile",      cacertfile_file],
  ["ldap_pre_auth",   "tls_cacertdir",       caertdir],
  ["ldap_pre_auth",   "tls_req_cert",        node[:ldap][:tls_req_cert]],
  ["ldap_pre_auth",   "non_ldap_users",      node[:ldap][:non_ldap_users]],
  ["auto_population", "default_project",     node[:ldap][:default_project]],
  ["auto_population", "default_role",        node[:ldap][:default_role]]
]

options.each do |option|
    execute "set option #{option}" do
      action :run
      command "/usr/bin/openstack-config --set #{node[:ldap][:keystone_config_file]} '#{option[0]}' '#{option[1]}' '#{option[2]}'"
    end
end

paste_options = [
  [ "pipeline:public_api", "pipeline",             "access_log sizelimit url_normalize token_auth admin_token_auth xml_body json_body simpletoken ldapauth autopop ec2_extension user_crud_extension public_service"],
  [ "pipeline:admin_api",  "pipeline",             "access_log sizelimit url_normalize token_auth admin_token_auth xml_body json_body simpletoken ldapauth autopop ec2_extension s3_extension crud_extension admin_service"],
  [ "pipeline:api_v3",     "pipeline",             "access_log sizelimit url_normalize token_auth admin_token_auth xml_body json_body simpletoken ldapauth autopop ec2_extension s3_extension service_v3"],
  [ "filter:simpletoken",  "paste.filter_factory", "keystone.middleware.simpletoken:SimpleTokenAuthentication.factory"],
  [ "filter:ldapauth",     "paste.filter_factory", "keystone.middleware.ldapauth:LdapAuthAuthentication.factory"],
  [ "filter:autopop",      "paste.filter_factory", "keystone.middleware.autopop:AutoPopulation.factory"]
]

paste_options.each do |option|
    execute "set option #{option}" do
      action :run
      command "/usr/bin/openstack-config --set #{node[:ldap][:keystone_paste_file]} '#{option[0]}' '#{option[1]}' '#{option[2]}'"
    end
end

service "openstack-keystone" do
   action :restart
end
