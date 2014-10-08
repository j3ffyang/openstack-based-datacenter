# About this page

### Figure 1. Layer three network solution
![control flow](http://bejgsa.ibm.com/home/l/i/lijs/web/public/images/layer_3_networks_solution.png)

> Management network

>     Used for internal communication between OpenStack Components. The IP addresses on this network should be reachable only within the data center and is considered the Management Security Domain. 

> Guest network

>     Used for VM data communication within the cloud deployment. The IP addressing requirements of this network depend on the OpenStack Networking plugin in use and the network configuration choices of the virtual networks made by the tenant. This network is considered the Guest Security Domain. 

> External network

>     Used to provide VMs with Internet access in some deployment scenarios. The IP addresses on this network should be reachable by anyone on the Internet and is considered to be in the Public Security Domain. 

### Figure 2. Requirements

    Switch Name| Remote control | Usage |    Network    |    Gateway    |Vlan|Active|
    R24-36      172.29.27.1      Router   172.16.27.1/24        -         1    up
      -                -           -      172.29.27.1/24        -         1    up
      -                -           -      172.29.26.1/24        -         1    up
      -                -           -      172.29.101.1/24       -         1    up
      -                -           -      172.29.24.1/24        -         1    up
      -                -           -      172.16.24.1/24        -         1    up
      -                -           -      9.115.78.12/16    9.115.78.1   644   up
      -                -           -      172.16.26.1/24        -         1    up
      -                -           -      9.115.77.12/16    9.115.78.1   644   up

    Management Network					
    R27-8       172.16.27.254    Manage         -          172.16.27.1    1    up
    R24-38      172.16.24.254    Manage         -          172.16.24.1    1    up
      -         10.10.6.1        L3-vlan  10.10.6.1/24         None      106   up
    
    IMM network	
    R28-21      172.29.27.253     IMM           -          172.29.27.1    1    up
    R26-38      172.29.27.251     IMM           -          172.29.27.1    1    up
      -         172.29.26.251     IMM           -               -         1    up
      -         172.29.24.251     IMM           -               -         1    up

    Data network		
    R27-2       9.115.78.14       Data         None        9.115.78.1    644   up
      -         9.111.102.13      extnl         -               -        644   up
      -                -          intnl   10.10.10.252/24       -        644   up
    R28-2       9.115.77.14       Data         None        9.115.77.1    644   up
      -         9.111.102.14      extnl         -               -        644   up

    Caths switch
    R24-37      9.115.77.15/16   Manage   172.16.101.1/24      None       1    up
