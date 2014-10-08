default[:ldap][:server]="bluegroups.ibm.com"
default[:ldap][:ssl_port]=636
default[:ldap][:user_tree_dn] = "ou=bluepages,o=ibm.com"
default[:ldap][:user_attribute_name] = "mail"
default[:ldap][:use_tls] = "True"
default[:ldap][:tls_cacertfile_file] = "bluepages.cer"
default[:ldap][:user_tree_dn] = "ou=bluepages,o=ibm.com"
default[:ldap][:user_attribute_name] = "mail"
default[:ldap][:tls_req_cert] = "allow"

default[:ldap][:non_ldap_users] = "ksadmin, admin, demo, nova, neutron, cinder, glance, monitoring"

default[:ldap][:default_project] = "demo"
default[:ldap][:default_role] = "_member_"

default[:ldap][:keystone_config_file] = "/etc/keystone/keystone.conf"
default[:ldap][:keystone_paste_file] = "/etc/keystone/keystone-paste.ini"
default[:ldap][:keystone_middleware_dir] = "/usr/lib/python2.6/site-packages/keystone/middleware"
