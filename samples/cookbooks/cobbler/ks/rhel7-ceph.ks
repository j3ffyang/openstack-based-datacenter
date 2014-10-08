#platform=x86, AMD64, or Intel EM64T
# System authorization information
auth  --useshadow  --enablemd5
#auth  --useshadow
# System bootloader configuration
#bootloader --location=partition --driveorder=sda --append="nomodeset rhgb quiet"
bootloader --location=mbr --boot-drive=sda
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
#keyboard us
keyboard --vckeymap=us --xlayouts='us'
# Network device used for installation
#network --bootproto=dhcp --device=eth0
#network --bootproto=dhcp --noipv6 --device=eno0
#network --bootproto=dhcp --noipv6 --device=bond0 --onboot=yes --bondslaves=eth0,eth1,eth2,eth3 --bondopts=mode=6,miimon=100
# System language
lang en_US
# Use network installation
url --url=$tree
# If any cobbler repo definitions were referenced in the kickstart profile, include them here.
#$yum_repo_stanza
# Network information
#$SNIPPET('network_config')
# Reboot after installation
reboot

#Root password
rootpw --iscrypted $default_password_crypted
#rootpw --plaintext passw0rd
# SELinux configuration
selinux --disabled
# Do not configure the X Window System
skipx
# System timezone
timezone  Asia/Hong_Kong --ntpservers=172.16.27.100
#timezone --ntpservers=172.16.27.100 Asia/Hong_Kong
# Install OS instead of upgrade
install
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel 
# Allow anaconda to partition the system as needed
#autopart
#part /boot/efi --asprimary --fstype="efi" --size=50
part /boot --asprimary --fstype="xfs" --size=200 --ondisk=sda
part / --fstype="xfs" --size=102400 --label=OS_ROOT --ondisk=sda
part /var/log --fstype="xfs" --size=40960 --label=OS_LOG --ondisk=sda
part /var --fstype="xfs" --grow --size=1 --label=OS_VAR --ondisk=sda

%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
# Enable installation monitoring
$SNIPPET('pre_anamon')
#!/bin/sh
#ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules
%end

%packages
@base
ntp
%end

%post
#!/bin/sh
#ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules
sed -i /^server/d /etc/ntp.conf
sync
echo "server 172.16.27.100 burst iburst prefer" >> /etc/ntp.conf
systemctl enable ntpd
systemctl start ntpd
#service ntpd restart
#chkconfig ntpd on
#$SNIPPET('log_ks_post')
# Start yum configuration 
#$yum_config_stanza
#cd /tmp
#wget http://172.16.27.200/gemini/scripts/install_compute.sh
#chmod +x install_compute.sh
#sh install_compute.sh > gemini_compute_install.log

(
cat <<'EOP'
[rhel-repo]
name=Red Hat Enterprise Linux $releasever - $basearch - Source
baseurl=http://172.16.27.100/rhel/7/x86_64/
enabled=1
gpgcheck=0
priority=1

[rhel-epel]
name=Extra Packages for Enterprise Linux 7 - $basearch
#baseurl=http://download.fedoraproject.org/pub/epel/6/$basearch
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch
failovermethod=priority
enabled=1
gpgcheck=0
proxy=http://172.16.27.100:8085/
priority=2

[rhel-epel-noarch]
name=Extra Packages for Enterprise Linux 7 - noarch
#baseurl=http://download.fedoraproject.org/pub/epel/6/$basearch
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=noarch
failovermethod=priority
enabled=0
gpgcheck=0
proxy=http://172.16.27.100:8085/
priority=2

[centos7-repo]
name=CentOS Linux $releasever - $basearch - Source
baseurl=http://172.16.27.100/centos/7/x86_64/
enabled=1
gpgcheck=0
priority=3

[scp]
name=SCP
baseurl=http://172.16.27.234:3080/scp
enable=1
gpgcheck=0
priority=4

[ceph]
name=Ceph packages for $basearch
baseurl=http://ceph.com/rpm/rhel7/x86_64
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc
proxy=http://172.16.27.100:8085/
priority=4

[ceph-noarch]
name=Ceph noarch packages
baseurl=http://ceph.com/rpm/rhel7/noarch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc
proxy=http://172.16.27.100:8085/
priority=4
EOP
) > /etc/yum.repos.d/cobbler-config.repo 

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
%end
# End final steps
