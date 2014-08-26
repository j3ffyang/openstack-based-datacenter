Mustang Networking setup is up to six distinct physical data center networks. These networks isolated in physical switch. 

![Network Architecture](images/20140820_mustang_networkarch.png)

## Management network
172.16.xx.xx/16 --1G cable connection
Used for internal communication between OpenStack Components. The IP addresses on this network should be reachable only within the data center and is considered the Management Security Domain. 

## VM network
10.0.xx.xx/16 -- 10G fiber connection
Used for VM data communication within the cloud deployment. The IP addressing requirements of this network depend on the OpenStack Networking plugin in use and the network configuration choices of the virtual networks made by the tenant. This network is considered the Guest Security Domain. 

## Storage network
10.10.xx.xx/16 --10G fiber connection
Used for Ceph storage, OSD access,etc

## Public network
9.110.178.0/24 --1G cable connection
Used to provide VMs with Internet access in some deployment scenarios. The IP addresses on this network should be reachable by anyone on the Internet and is considered to be in the Public Security Domain. 

## API network
9.110.178.0/24 -- 1G cable connection
Exposes all OpenStack APIs, including the OpenStack Networking API, to tenants. The IP addresses on this network should be reachable by anyone on the Internet. This may be the same network as the external network, as it is possible to create a subnet for the external network that uses IP allocation ranges to use only less than the full range of IP addresses in an IP block. This network is considered the Public Security Domain. 

## Integrated Management Module network
172.29.0.0/16 --1G cable connection, by OpenVPN dial-in 
Used to provides power support for integrated management module. The IP addresses on this network should be reachable by anyone on the internal networks, this maybe with the baremetal integration.
 
## Hostnaming
### r83x5u09
r83: rack 83
x5 : x3550, or x6= x3650
u09: at unit 09
