#platform=x86, AMD64, or Intel EM64T
# System authorization information
auth  --useshadow  --enablemd5
# System bootloader configuration
#bootloader --location=partition --driveorder=sda --append="nomodeset rhgb quiet"
bootloader --location=mbr --driveorder=sda
# Partition clearing information
# clearpart --all --initlabel
# Use text mode install
text
# Firewall configuration
# firewall --enabled
firewall --disable
# Run the Setup Agent on first boot
firstboot --disable
# System keyboard
keyboard us
# Network device used for installation
#network --bootproto=dhcp --device=eth0
# System language
lang en_US
# Use network installation
url --url=$tree
# If any cobbler repo definitions were referenced in the kickstart profile, include them here.
$yum_repo_stanza
# Network information
#$SNIPPET('network_config')
# Reboot after installation
reboot

#Root password
rootpw --iscrypted $default_password_crypted
# SELinux configuration
selinux --disabled
# Do not configure the X Window System
skipx
# System timezone
timezone  Asia/Hong_Kong
# Install OS instead of upgrade
install
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel 
# Allow anaconda to partition the system as needed
#autopart
#part /boot/efi --asprimary --fstype="efi" --size=50
part /boot --asprimary --fstype="ext4" --size=200
part / --fstype="ext4" --size=102400 --label=OS_ROOT #--onpart=LABEL=OS_ROOT #--onbiosdisk=80
part /var/log --fstype="ext4" --size=40960 --label=OS_LOG #--onpart=LABEL=OS_LOG #--onbiosdisk=80
part /var --fstype="ext4" --grow --size=1 --label=OS_VAR #--onpart=LABEL=OS_VAR #--onbiosdisk=80


%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
# Enable installation monitoring
$SNIPPET('pre_anamon')

%packages
$SNIPPET('func_install_if_enabled')
$SNIPPET('puppet_install_if_enabled')

%post
#$SNIPPET('log_ks_post')
# Start yum configuration 
#$yum_config_stanza
cd /tmp
wget http://172.16.27.200/gemini/scripts/install_compute.sh
chmod +x install_compute.sh
sh install_compute.sh > gemini_compute_install.log

#(
#cat <<'EOP'
#[rhel-source]
#name=Red Hat Enterprise Linux $releasever - $basearch - Source
#baseurl=http://172.16.27.200/rhel/6.5/x86_64/
#enabled=1
#gpgcheck=0

#[scp]
#name=SCP
#baseurl=http://172.16.27.201:3080/scp/
#enable=1
#gpgcheck=0

#EOP
#) > /etc/yum.repos.d/cobbler-config.repo 

#yum -y  install chef
#ntpdate 172.16.27.200
#rm -rf /etc/chef
#mkdir /etc/chef
#rm -rf /root/.chef
#mkdir /root/.chef

#wget "http://172.16.27.199/cblr/pub/admin.pem" -O  /etc/chef/admin.pem
#wget "http://172.16.27.199/cblr/pub/client.rb"  -O  /etc/chef/client.rb
#wget "http://172.16.27.199/cblr/pub/knife.rb" -O  /root/.chef/knife.rb
#wget "http://172.16.27.199/cblr/pub/validation.pem" -O /etc/chef/validation.pem

# End yum configuration
#$SNIPPET('post_install_kernel_options')
#$SNIPPET('post_install_network_config')
#$SNIPPET('func_register_if_enabled')
#$SNIPPET('puppet_register_if_enabled')
#$SNIPPET('download_config_files')
#$SNIPPET('koan_environment')
#$SNIPPET('redhat_register')
#$SNIPPET('cobbler_register')
# Enable post-install boot notification
#$SNIPPET('post_anamon')
# Start final steps
$SNIPPET('kickstart_done')
# End final steps
