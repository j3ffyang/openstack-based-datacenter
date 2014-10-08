### Architecture

### Figure 1.1. Physical network diagram
![control flow](http://bejgsa.ibm.com/home/l/i/lijs/web/public/images/layer_1_pyhsical_network.png)

### Requirements

shows an IBM BNT RackSwitch G8264.
![control flow](http://bejgsa.ibm.com/home/l/i/lijs/web/public/images/ibm-G8124-G8000-switch.png)

	Total 3 physical BNT G8000, 1 physical G8124

shows an IBM iDataPlex:
![control flow](http://bejgsa.ibm.com/home/l/i/lijs/web/public/images/ibm-idataplex-dx360-m4.png)

	Total 22 physical machine disk:
	600G * 2

	Total 6 physical machine disk:
	600G * 1

	Total 24 physical machine two nic:
	Ethernet 2*1(IMM management)

	Total 4 physical machine three nic:
	Ethernet 4*1(IMM management)


### The Physical machines list:
    Rack 27 IMM ip addresses:
    172.29.27.101
    172.29.27.1
    172.29.27.2
    172.29.27.4
    172.29.27.5
    172.29.27.6
    172.29.27.10
    172.29.27.11
    172.29.27.12
    172.29.27.13
    172.29.27.14
    172.29.27.15
    172.29.27.16
    172.29.27.17
    172.29.27.19
    172.29.27.24
    172.29.27.27

    Rack 28 IMM ip addresses:
    172.29.28.2
    172.29.28.6
    172.29.28.7
    172.29.28.8
    172.29.28.9
    172.29.28.10
    172.29.28.11
    172.29.28.13
    172.29.28.15
    172.29.28.17
    172.29.28.18

#### We need at least three physical BNT G8000
#### We need at least one physical switch G8124
