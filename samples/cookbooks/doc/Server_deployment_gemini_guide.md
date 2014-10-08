#How to deploy new machine into Gemini


> This article mainly describes how to install a new hardware into Gemini systems within bios utility, IMM console, ASU, cobbler toolkits, and how to create a configuration suitable for automatically installing multiple client machines. the  include following steps:

+ Enable ethernet cable connection, activate the IMM service, configuration IMM name and IP address.   
+ Create RAID on IBM Server.
+ Remote update IMM with ASU for compliant of Gemini. 
+ Add new system in cobbler .   
+ installtion/re-install RHEL65. 




####Requirement:

+ cobbler server depolyed properly.        
+ Network connection of IMM and cobbler are well configured. 

---

### IMM activation and configure IP and IMM name

1.reboot the target server.    

2.press F12 button when the screen displays "Connecting boot devices and adapters".  

3.System Settings->Integrated Management Module

4.Enable "Command on USB interface" Item.

5.Modify the Networking->HostName. The HostName is IMM name, it should be the 'AAA_BBB_CCC' format, the description of each section below:

  AAA: 'R' + rack number as its value,if the server deployed on the thirtieth rack, the AAA will be "R30".    
  BBB: sub server type subname ,for example, the server type is IBM system x3550,could use x5.    
  CCC: the unit sequence number in rack, eg 100.  

6.Set NetWorking->DHCP Control "static ip".   

7.Modify NetWorking->IP Address as expected. The IP is 172.29.'RAC number'.'Unit number'.   

8.Modify NetWorking->Subnet Mask use proper value. the default subnet mask is '255.255.255.0'. 

9.Use switcher ip address as the NetWorking->Default Gateway. usually the gateway ip is in the same subnet, if the IMM ip is 172.29.30.13, the gateway ip should be 172.29.30.1 .   

10.save the bios configuration and restart.

---

### Activate the Fod option and retrieve the activation key file

1.Locate the authorization code at the top of function authorization document.  

2.Make sure that you have access to the hardware that you want to activate.   

3.Login to [IBM system x Fod site](http://www.ibm.com/systems/x/fod/).   

4.Select Request Activation Key from the left navigation panel.   

5.Enter the authorization code and click Continue.   

6.Follow the instructions on the web page to activate the Features on Demand option and verify that the request is successful.   

7.The activation key file is sent to the email address that you provide during the activation process.   

8.login to the IMM web console: https://[IBM Server's IMM ip], (eg. https://172.29.24.11). use USERID/PASSW0RD as username and password.   

9.IMM Management -> Activation key management .   

10.Add the activation key file created in previous section.   

11.Check the status of the activation key. if the status is "Activation key is valid", the Fod activation operation is successful.
    

------

### Create RAID on Power 

When the host computer boots, hold the <Ctrl> key and press the <H> key when the following text appears:

press <Ctrl><H> for WebBIOS After you press <Ctrl><H> or Press <Ctrl><Y> to use CLI, the Adapter Selection screen displays. You use this screen to select the adapter that you want to configure. Select an adapter and press Start to begin the configuration. 

1.choose "configuration Wizard"

2.choose "add new configuration"

3.recommand using auto configuration for Raid Creation:

    RAID0: if the option "auto configuration without redundancy" is selected, the RAID0 will be created.
    
    RAID1: if the option "Auto configuration with redundancy" is selected, and there're only two hard disk installed on server, RAID1 will be create.   
    
    RAID5: if the option "Auto configuration with redundancy" is selected, and there're more than two hard disk installed on server, RAID5 will be create.

4.Choose "Yes" to keep the configuration", continue.

5.Choose "Yes" to initialize the virtual driver, continue.

6.after the webbios complete raid creation, you can check if the status of creation from the left panel of Web bios GUI .

------

## IMM remote update with ASU for compliant with Gemini   

Use the IBM® Advanced Settings Utility (ASU) to modify firmware settings from
the command line on multiple operating-system platforms.    

The ASU supports scripting environments because it is a command-line utility. It
also offers easier scripting through its batch-processing mode.


####Query PXE boot Mac address
all the information of MAC address of your network devices should be retrieved  to enable/disable PXE boot setting.The host name should be IMM's name you configured in above steps.    

    # ./asu64 show all --host 192.29.24.100 --USER USERID --password PASSW0RD | grep "PXE.NicPortMacAddress"

A lower version of IMM firmware can not show the "PXE.NicPortMacAddress", then the "iSCSI.MacAddress" would be a workaround, but it would include all the MACs supporting iSCSI.
    
    # ./asu64 show all --host 192.29.24.100 --USER USERID --password PASSW0RD | grep "iSCSI.MacAddress"
   
    
####Enable/Disable the PXE Mode for networking device
    
disable PXE Mode for other network device except the one connect to the cobbler server.    
    # ./asu64 set PXE.NicPortPxeMode.1 "Legacy Support" --host 192.29.27.100 --user XXXX --password XXXXX

    
    
    # ./asu64 set PXE.NicPortPxeMode.2 Disabled --host 192.29.27.100 --user XXXXX --password XXXXX      

    
#### change the boot order, change the PXE boot up mode as the primary choice 
    # ./asu64 set BootOrder.BootOrder "PXE Network=CD/DVD Rom=Legacy Only=Hard Disk 0" --host 192.29.24.100 --user USERID --password PASSW0RD

    
---
## Cobbler new system registration    

  Once the distributions and profiles for Cobbler have been created, you can next add systems to Cobbler. System records map a piece of hardware on a client with the cobbler profile assigned to run on it.  
  
   The following command adds a system to the Cobbler configuration: 
    
    cobbler system add --name=R27-IDP-100 --profile=RHEL65-x86_64 --interface=eth0 --mac=E4:1F:13:EF:33:F6 --ip-address=192.16.27.100 --netmask=255.255.255.0 --gateway=192.16.27.1 --hostname=R27-IDP-100 --power-type=imm --power-address=192.29.27.100 --power-user=XXXXX --power-pass=XXXX --server=192.16.27.199 
    
The --name=string is the unique label for the system, such as engineeringserver or frontofficeworkstation.    

The --profile=string specifies one of the profile names added in Cobbler.    

The --mac=AA:BB:CC:DD:EE:FF option allows systems with the specified MAC address to automatically be provisioned to the profile associated with the system record if they are being kickstarted.  

The --server=192.16.27.199, The IP of cobbler server, in our project, we use 172.16.27.199 for cobbler's IP.

For more options, such as setting hostname or IP addresses, refer to the Cobbler manpage by typing man cobbler at a shell prompt. 
   
_\*Remember to apply all the changes to the filesystem to make the configuration take affect:_

    cobbler sync


Finally, you can install the machines.
   
   BTW,If you register a system with incorrect configuration in cobbler, you can use 'cobbler system remove' to get rid of it.    
    
    cobbler system remove --name=R27-IDP-100
   
---
## RHEL65 installation/re-install   

You're ready to boot the machines and install them. They must be configured to boot from the network — if they aren't, they might boot from the hard disk and never start the installation. If you activated power management, Cobbler can reboot the machine for you so you can start the installation with a simple command:

    cobbler system reboot --name=R27-IDP-100

The Server restarts with a network boot and receives the boot files from Cobbler. The installation takes place automatically, and the process ends when the Redhat login screen is displayed.
