#Gemini Production deployment

## Deployment topology for Over cloud

Deploy over cloud on existing servers.

* Central server node:
 * DB2, Horizon AdminUI, qpid, keystone, Neutron, IaasGateway, LDAP config, BPM, SCUI
* KVM region:
 * Heat, Nova Controller, Cinder, Glance, Ceilometer related.
* Compute node:
 * Compute node, linuxbridge agent 

Network configuration

* deployment service node: 
    * network interface: eth0
    * IP: 9.115.78.75
* Other nodes in over cloud: 
    * network interface: eth1
    * Central server node IP: 9.115.78.90
    * KVM region IP: 9.115.78.91
    * Compute Node IP: 9.115.78.78
* Launched VM:
    * vxlan  
    * IP range: 10.11.0.2 ~ 10.11.254.254


## Deployment Procedure

The following steps are temporary since more hacks are not included in product integration build yet.

1. The default `iproute` package in RHEL65 should be upgraded on all compute nodes, here is [yum repo](http://9.110.51.34/extention/iproute-2.6.32-130.el6ost.netns.2.x86_64.rpm) for the package

1. Update `<installation-package>/data/openstack/metadata.json`

    
    ========================================================================================
    key              original value  ---> updated value
    ========================================================================================
    "core_plugin"               "neutron.plugins.linuxbridge.lb_neutron_plugin.LinuxBridgePluginV2",  --->  "neutron.plugins.ml2.plugin.Ml2Plugin",
    "network_vlan_ranges"       "physnet1:1000:1100", ---> "physnet1",
    "tenant_network_type"       "vlan" --->  "flat,vlan,vxlan"
    "use_namespaces"            "False" --->   "True"
    "linuxnet_interface_driver" "nova.network.linux_net.LinuxBridgeInterfaceDriver" --> "nova.network.linux_net.NeutronLinuxBridgeInterfaceDriver"
    ========================================================================================

    Add the following under "openstack" -> "network":

    "linuxbridge":{
        "local_ip_interface": "eth1",
        "firewall_driver": ""
    }


1. Replace cookbook <installation-package>/data/openstack/chef-repo/cookbooks/openstack-network/ with Catherine's fix [here](http://172.16.0.11/jbe_setup/openstack-network.tgz)
1. Copy template file in this gemini probject under `topology-templates/gemini_kvm_region_neutron.json` to `<installation-package>/topology-template/templates/`
1. Copy role files `gemini_allinone.json`, `gemini_compute.json`, `kvm_region` in this gemini project under `chef-repo/roles/` to `<installation-package>/data/installer/chef-repo/roles/`
1. Copy cookbook `ldap` in this project to to `<installation-package>/data/installer/chef-repo/cookbooks/`
1. Update cookbook `openstack/chef-repo/cookbooks/openstack-common/libraries/endpoint.rb` with ZhengYou's fix to resolve db2 database name issue.


    def db(service)    
        if node.run_list.expand(node.chef_environment).roles.include?('os-ops-database')
          db_server_node = node
        else
          db_server_node = search_for('os-ops-database').first
        end
        db_server_node['openstack']['db'][service]
      rescue
        nil
      end


1. Run deployment service by `deploy_deployment_service.sh -p passw0rd`
1. Create node, create job, execute job to finish the deployment
1. Apply neutron patch on neutron server and all compute nodes
 1. Download patch file [here](http://9.181.26.252/jbe_setup/neutron.patch)
 1. On neutron server, run the following commands:


    cp -r /usr/lib/python2.6/site-packages/neutron /root/
    cd /usr/lib/python2.6/site-packages/
    patch -p1 < /root/neutron.patch
    
 1. restart all services after applying patch:
    

    restart service on all in one node:
    /etc/init.d/neutron-dhcp-agent restart
    /etc/init.d/neutron-l3-agent restart
    /etc/init.d/neutron-linuxbridge-agent restart
    /etc/init.d/neutron-metadata-agent restart
    /etc/init.d/neutron-server restart
    
    restart service on compute node:
    /etc/init.d/neutron-linuxbridge-agent restart


1. Install `mox` on node installed with SCO horizon, control node in gemini production env

    wget https://pymox.googlecode.com/files/mox-0.5.3.tar.gz
    tar xvzf mox-0.5.3.tar.gz
    cd mox-0.5.3
    python setup.py install
    service httpd restart 


1. Verify the installation


    wget http://172.17.32.13/SCP_VM_images/rhel65-ext3-fs.qcow2
    glance image-create --name=rhel65-ext3-fs --is-public=true --container-format=bare --disk-format=qcow2 < /root/rhel65-ext3-fs.qcow2


1. Create network:

    
    Using flat:
    neutron net-create public --router:external=True --provider:network_type flat --provider:physical_network physnet1
    neutron subnet-create  --gateway 172.17.48.1 public 172.17.48.0/22 --allocation-pool start=172.17.48.70,end=172.17.48.71 --name public_sub

    Using vxlan:
    neutron net-create private_net --provider:network_type vxlan --provider:segmentation_id 1000
    neutron subnet-create private_net 10.11.0.0/16  --allocation-pool start=10.11.0.2,end=10.11.255.255 --name private_sub
    neutron router-create router
    neutron router-gateway-set router public
    neutron router-interface-add router private_sub
    nova boot --image <image-id> --flavor m1.small --nic net-id <private net id> <vm name>
    ip netns list
    ip netns exec <netns-id> ping <vm ip in vxlan>


