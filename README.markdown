## [Design Thoughts and Architecture Overview](ArchitectureOverview.markdown)
  * Principle and Belief

## [Disk Configuration](DiskConfiguration.markdown)
  * Configuration Spec on Controller, Compute and Storage Node Respectively
  * RAID Group Configuration
  * Caching on RAID Card
  * Disk Partition Layout

## [Network Architecture](NetworkConfiguration.markdown)
  * Network Segmentations

## [Hostnaming and IP Planning](IPPlanning.markdown)
  * IP Range and Reservation Plan

## [Hardware Specification](HardwareSpec.markdown)
  * Machine Location and Cabling, MAC Address, Switch Information, etc.

## 1st Controller Physical Box
  * [Build the 1st Controller Physical Box](BuildFirstBox.markdown)
  * [Install and Configure OpenVPN](InstallAndConfigureOpenvpn.markdown)

## [CentOS Repo](CreateCentosRepo.markdown)

## [Build an Image](BuildAnImage.markdown)

## [Cobbler Configuration and Template](BuildCobblerVM.markdown)
  * Bare- metal provisioning

## Chef Automation
  * [Chef Repository](ChefRepo.markdown)
  * [Chef Client](ChefClient.markdown), including how deployment works after VM/ hosts provisioned

## [Jenkins](BuildJenkins.markdown)

## [Controller VMs](BuildControllerVM.markdown)
  * Respectively host clusters of MySQL, queue, etc

## Distributed Storage by Ceph
  * [Ceph Host Preparation](CephPrepare.markdown)
  * [Ceph Partition](CephPartition.markdown)
  * [Ceph Node Configuration](CephDistributedStorage.markdown)

## Deploy OpenStack
  * Chef Architecture
  * Git Architecture
  * OpenStack Cookbook Repo

## Software Defined Network
  * Neutron HA

## Apply HA
  * Galera
  * RabbitMQ Cluster

## Operation
  * One rule everybody should remember is to run "who" and "wall" prior to shutdown the server!
  * Monitoring by Ganglia, Nagios
  * Log Analysis by Logstash

## [Troubleshooting](TroubleShooting.markdown)
