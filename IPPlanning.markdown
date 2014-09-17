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
| Hostname | NIC0/br0 | NIC1/br1 | NIC2/br2 | NIC3/br3 | IMM | Function |
| -------- | ---- | ---- | ---- | ---- | ---- | ---- |
| r83x5u09 | 172.16.0.21 | 9.110.178.28 | 172.29.83.249 | | 172.29.83.9 | controller host. NIC3/br3's IP provides bridge to Cobbler VM to connect into IMM network |
| r83x6u16 | 172.16.0.201 | | 172.18.0.201 | 172.17.0.201 | 172.29.83.16 | storage node, mounted at unit 16 on rack 83. 172.18 connecting to VM network and 172.17 connecting to Ceph network |
| r83x6u18 | 172.16.0.202 | | 172.18.0.202 | 172.17.0.202 | 172.29.83.18 | storage node, mounted at unit 18 on rack 83. 172.18 connecting to VM network and 172.17 connecting to Ceph network |
| r83x6u20 | 172.16.0.203 | | 172.18.0.203 | 172.17.0.203 | 172.29.83.20 | storage node, mounted at unit 20 on rack 83. 172.18 connecting to VM network and 172.17 connecting to Ceph network |
| |  |  |  |  |  |
| cobbler | 172.16.0.31 | | 172.29.0.31 | |
| chef | 172.16.0.32 | | | |
| ctrlr0 | 172.16.0.33 | | | |
| ctrlr1 | 172.16.0.34 | | | |
| ctrlr2 | 172.16.0.35 | | | |
| jenkins | 172.16.0.36 | | | |
