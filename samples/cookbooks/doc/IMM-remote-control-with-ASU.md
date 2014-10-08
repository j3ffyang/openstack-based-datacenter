<!-- title: How to use the Advanced Settings Utility (ASU) to control the IMM remotely -->

The Advanced Settings Utility (ASU) can be used to control the IMM remotely, like query the PXE nic MAC address, change boot order, reboot the machine, etc.

### Download and unzip the Advanced Settings Utility (ASU)

[Download Advanced Settings Utility: http://www-947.ibm.com/support/entry/portal/docdisplay?lndocid=TOOL-ASU]

### Power 0ff/On machine

    # ./asu64 immapp poweroffos --host 172.29.101.62 --USER USERID --password PASSW0RD                            
    IBM Advanced Settings Utility version 9.41.81K
    Licensed Materials - Property of IBM
    (C) Copyright IBM Corp. 2007-2013 All Rights Reserved
    Connected to IMM at IP address 172.29.101.62
    Server Powered off!

    # ./asu64 immapp poweronos --host 172.29.101.62 --USER USERID --password PASSW0RD  
    IBM Advanced Settings Utility version 9.41.81K
    Licensed Materials - Property of IBM
    (C) Copyright IBM Corp. 2007-2013 All Rights Reserved
    Connected to IMM at IP address 172.29.101.62
    Server Powered On!
    # 

### Query PXE boot Mac address

    # ./asu64 show all --host 172.29.101.62 --USER USERID --password PASSW0RD | grep "PXE.NicPortMacAddress"
    PXE.NicPortMacAddress.1=34-40-B5-9F-7E-DC
    PXE.NicPortMacAddress.2=34-40-B5-9F-7E-DE

A lower version of IMM firmware can not show the "PXE.NicPortMacAddress", then the "iSCSI.MacAddress" would be a workaround, but it would include all the MACs supporting iSCSI.
    
    # ./asu64 show all --host 172.29.101.62 --USER USERID --password PASSW0RD | grep "iSCSI.MacAddress"
    iSCSI.MacAddress.1=34-40-B5-9F-7E-DC
    iSCSI.MacAddress.2=34-40-B5-9F-7E-DE
    iSCSI.MacAddress.3=00-00-C9-F6-77-28
    iSCSI.MacAddress.4=00-00-C9-F6-77-2C
    
### Enable/Disable the PXE for next boot
    
    # ./asu64 set IMM.PXE_NextBootEnabled Enabled --host 172.29.101.62 --user USERID --password PASSW0RD
    IBM Advanced Settings Utility version 9.41.81K
    Licensed Materials - Property of IBM
    (C) Copyright IBM Corp. 2007-2013 All Rights Reserved
    Connected to IMM at IP address 172.29.101.62
    IMM.PXE_NextBootEnabled=Enabled
    Waiting for command completion status.
    Command completed successfully.
    
    # ./asu64 set IMM.PXE_NextBootEnabled Disabled --host 172.29.101.62 --user USERID --password PASSW0RD       
    IBM Advanced Settings Utility version 9.41.81K
    Licensed Materials - Property of IBM
    (C) Copyright IBM Corp. 2007-2013 All Rights Reserved
    Connected to IMM at IP address 172.29.101.62
    IMM.PXE_NextBootEnabled=Disabled
    Waiting for command completion status.
    Command completed successfully.
