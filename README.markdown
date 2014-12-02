## [Design Thoughts and Architecture Overview](markdown/ArchitectureOverview.markdown)
  * Principle and Belief

## Pre- install Preparation
  * [Hardware Specification](markdown/HardwareSpec.markdown)
  * [Disk Configuration](markdown/DiskConfiguration.markdown)
  * [Build the 1st Controller Physical Box](markdown/BuildFirstBox.markdown)
  * [Build an Image](markdown/BuildAnImage.markdown)
  * [Cobbler Configuration and Template](markdown/BuildCobblerVM.markdown)
  * [Setup an NTP Server](markdown/CreateNTP.markdown)
  * [CentOS Repo](markdown/CreateCentosRepo.markdown)
  * [Update /etc/hosts](markdown/UpdateHosts.markdown)

## Network
  * [Architecture and Segment](markdown/NetworkConfiguration.markdown)
  * [Hostnaming and IP Planning](markdown/IPPlanning.markdown)
  * [Physical Host and Controller VM Network](markdown/BuildFirstBox.markdown)
  * [Install and Configure OpenVPN](markdown/InstallAndConfigureOpenvpn.markdown)
  * [Cobbler VM Network](markdown/BuildCobblerVM.markdown)
  * [Ceph Network](markdown/CephDistributedStorage.markdown)
  * [Neutron Network](markdown/BuildNeutron.markdown)

## Chef Automation
  * [Chef Repository](markdown/ChefRepo.markdown)
  * [Chef Client](markdown/ChefClient.markdown), including how deployment works after VM/ hosts provisioned

## Distributed Storage by Ceph
  * [Ceph Host Preparation](markdown/CephPrepare.markdown)
  * [Ceph Partition](markdown/CephPartition.markdown)
  * [Ceph Node Configuration](markdown/CephDistributedStorage.markdown)
  * [Add New Ceph OSD](markdown/CephAddOSD.markdown)
  * [Add New Monitor](markdown/CephAddMon.markdown)
  * [Post Install Configuration and Verify](markdown/CephPostConfiguration.markdown)
  * [Modify Ceph Parameter](markdown/CephParamChange.markdown)
  * [Repair Inconsistent Page Groups](markdown/CephPGRepair.markdown)

## Deployment
  * [Prepare Controller VMs and Create Snapshot](markdown/BuildControllerVM.markdown)
  * Deploy HAProxy and Keepalived
  * [Deploy Galera Cluster](markdown/DeployGalera.markdown)
  * [Deploy RabbitMQ Cluster](markdown/DeployRabbitMQCluster.markdown)
  * [Deploy OpenStack](markdown/DeployOpenStack.markdown)
  * [Build Neutron Controller](markdown/BuildNeutron.markdown)
  * [Register Image](markdown/RegisterImage.markdown)

## Software Defined Network
  * [Neutron Operation](markdown/NeutronOperation.markdown)
  * Neutron HA

## Stress Test
  * [Network Performance Test](markdown/StressTestNetwork.markdown)
  * [Ceph Stress Test](markdown/StressTestCeph.markdown)
  * [MySQL Stress Test](markdown/StressTestMySQL.markdown)

## Operation
  * When [adding new VM](markdown/PostConfigNewVM.markdown)
  * Log Analysis by [Logstash](markdown/BuildELKStack.markdown)
  * Monitoring by Ganglia, Nagios
  * [Jenkins](markdown/BuildJenkins.markdown)
  * One rule everybody should remember is to run "who" and "wall" prior to shutdown the server!

## [Troubleshooting](markdown/TroubleShooting.markdown)
