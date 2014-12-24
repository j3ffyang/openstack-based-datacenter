## Design Thoughts
1. In OpenStack framework
2. It's a Cloud, which is dynamic, not static. Self service enabled. You get what you want almost immediately.
3. It's a production in data center with high traffic of CPU, disk and network.

### Technically, the architecture would look like

+ General scope into 
![Overall Scope](/images/20140814_architectureoverview_svc.png)
(a) OpenStack framework, 
(b) SDN capability, 
(c) Distributed storage and 
(d) DevOps in production operation
* SDN - we choose Neutron with high availability configuration for now. 
* Distributed storage by Ceph to hold VM instances/ Cinder volumes/ Glance images. At least into 3 copies across physical compute nodes.
* Overall network architecture has 5 network segmentations
  * Management network - all OpenStack controllers, HA components, APIs calls
  * VM network - traffic between VMs. Fiber network preferred
  * Storage network - dedicated for distributed storage, driven by Ceph (or GPFS). Fiber network preferred
  * External to internet/ public network
  * IMM - integrated management module to maintenance (optional)
* High Availability design for all components, at least 3 nodes (node could be VM or physical boxes)
  * Galera active- active for MySQL database for OpenStack
  * RabbitMQ with its own native cluster feature
  * Neutron HA 

