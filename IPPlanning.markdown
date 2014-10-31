## Hostnaming
### r83x5u09
| Breakdown | Specification |
| --- | ------- |
| r83 | rack 83 |
| x5 | x3550, or x6= x3650 |
| u09 | mounted at unit 09 |

## IP Plan for Management Network (172.16.0.0/16)
| IP Start | IP End | Reserved for |
| -------- | ------ | ------------ |
| 2 | 20 | System's like DNS, proxy... |
| 21 | 30 | Controller host (up to 10 physical controllers) |
| 31 | 100 | OpenStack controllers, HA, OSS (monitoring, log analysis...) |
| 101 | 200 | Compute |
| 201 | 240 | Storage |
| 241 | 249 | VPN for maintenance |

## IP Reservation. Also defined at [/etc/hosts](samples/hosts/hosts)
Referring to [network architecture](NetworkConfiguration.markdown)

Physical Host

| Hostname | NIC0/br0/Mgmt | NIC1/br1/Public | NIC2/br2/IMM | NIC3/br3/Ceph Public/fiber | IMM |
| -------- | ---- | ---- | ---- | ---- | ---- | ---- |
| r83x5u09 | 172.16.0.21 | 9.110.178.28 | 172.29.83.249 | 10.0.0.21 | 172.29.83.9 | 
| r83x5u08 | 172.16.0.22 | 9.110.178.27 | 172.29.83.248 | 10.0.0.22 | 172.29.83.8 |

Ceph Distributed Host

| Hostname | NIC0/br0/Mgmt | NIC1/br1 | NIC2/br2/Ceph public/fiber | NIC3/br3/Ceph private/fiber | IMM |
| -------- | ---- | ---- | ---- | ---- | ---- |
| r83x6u16 | 172.16.0.201 | | 10.0.0.201 | 10.10.0.201 | 172.29.83.16 | 
| r83x6u18 | 172.16.0.202 | | 10.0.0.202 | 10.10.0.202 | 172.29.83.18 |
| r83x6u20 | 172.16.0.203 | | 10.0.0.203 | 10.10.0.203 | 172.29.83.20 |

Compute Host

| Hostname | NIC0 |
| -------- | ---- |
| r83x6u14 | 172.16.0.101 |
| r83x6u12 | 172.16.0.102 |
| r83x6u10 | 172.16.0.103 |

Controller VM

| Hostname | NIC0 | NIC1 | NIC2 | NIC3 | 
| -------- | -------- | -------- | -------- | -------- | 
| cobbler | 172.16.0.31 | | 172.29.83.31/24 | |
| chef | 172.16.0.32 | | | |
| ctrlr0 | 172.16.0.33 | 10.0.0.33 | | |
| ctrlr1 | 172.16.0.34 | 10.0.0.34 | | |
| ctrlr2 | 172.16.0.35 | 10.0.0.35 | | |
| jenkins | 172.16.0.36 | | | |
| vIP | 172.16.0.37 | | | |
| neutron | 172.16.0.38 | 10.0.0.38 | Neutron doesn't need an external IP. It requires a physical link to external network. | 
| logstash | 172.16.0.39 | | | |

The maintenance network, 172.29.83.0, sub netmask is 24. (Not 16)
