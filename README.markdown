## [Design Thoughts and Architecture Overview](ArchitectureOverview.markdown)
  * Principle and Belief

## Pre- install Preparation
  * [Hardware Specification](HardwareSpec.markdown)
  * [Disk Configuration](DiskConfiguration.markdown)
  * [Build the 1st Controller Physical Box](BuildFirstBox.markdown)
  * [Build an Image](BuildAnImage.markdown)
  * [Cobbler Configuration and Template](BuildCobblerVM.markdown)
  * [Setup an NTP Server](CreateNTP.markdown)
  * [CentOS Repo](CreateCentosRepo.markdown)
  * [Update /etc/hosts](UpdateHosts.markdown)

## Network
  * [Architecture and Segment](NetworkConfiguration.markdown)
  * [Hostnaming and IP Planning](IPPlanning.markdown)
  * [Physical Host and Controller VM Network](BuildFirstBox.markdown)
  * [Install and Configure OpenVPN](InstallAndConfigureOpenvpn.markdown)
  * [Cobbler VM Network](BuildCobblerVM.markdown)
  * [Ceph Network](CephDistributedStorage.markdown)
  * [Neutron Network](BuildNeutron.markdown)

## Chef Automation
  * [Chef Repository](ChefRepo.markdown)
  * [Chef Client](ChefClient.markdown), including how deployment works after VM/ hosts provisioned

## Distributed Storage by Ceph
  * [Ceph Host Preparation](CephPrepare.markdown)
  * [Ceph Partition](CephPartition.markdown)
  * [Ceph Node Configuration](CephDistributedStorage.markdown)
  * [Add New Ceph OSD](CephAddOSD.markdown)
  * [Add New Monitor](CephAddMon.markdown)
  * [Post Install Configuration and Verify](CephPostConfiguration.markdown)

## Deployment
  * [Prepare Controller VMs and Create Snapshot](BuildControllerVM.markdown)
  * Deploy HAProxy and Keepalived
  * [Deploy Galera Cluster](DeployGalera.markdown)
  * [Deploy RabbitMQ Cluster](DeployRabbitMQCluster.markdown)
  * [Deploy OpenStack](DeployOpenStack.markdown)
  * [Build Neutron Controller](BuildNeutron.markdown)

## Software Defined Network
  * Neutron HA

## Operation
  * When [adding new VM](PostConfigNewVM.markdown)
  * Log Analysis by [Logstash](BuildLogstash.markdown)
  * Monitoring by Ganglia, Nagios
  * [Jenkins](BuildJenkins.markdown)
  * One rule everybody should remember is to run "who" and "wall" prior to shutdown the server!

## [Troubleshooting](TroubleShooting.markdown)
