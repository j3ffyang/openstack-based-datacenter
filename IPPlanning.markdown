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

## IP Reservation
| Hostname | NIC0/br0 | NIC1/br1 | NIC2/br2 | 
| -------- | ---- | ---- | ---- |
| r83x5u09 | 172.16.0.21 | 9.110.178.28 | 172.29.83.249 |
|  |  |  |  | 
| cobbler | 172.16.0.31 | | 172.29.0.31 |
