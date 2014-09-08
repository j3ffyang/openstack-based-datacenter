## Copy CentOS ISO to FirstBox under /mnt
    [root@r83x5u09 mnt]# mv ~/CentOS-7.0-1406-x86_64-DVD.iso .
    [root@r83x5u09 mnt]# ls
    CentOS-7.0-1406-x86_64-DVD.iso
    [root@r83x5u09 mnt]# pwd
    /mnt

## Mount ISO
	[root@r83x5u09 mnt]# mkdir centos7_64
	[root@r83x5u09 mnt]# mount -o loop CentOS-7.0-1406-x86_64-DVD.iso centos7_64/

## Install createrepo RPM
	[root@r83x5u09 Packages]# rpm -Uvh createrepo-0.9.9-23.el7.noarch.rpm deltarpm-3.6-3.el7.x86_64.rpm python-deltarpm-3.6-3.el7.x86_64.rpm 
	warning: createrepo-0.9.9-23.el7.noarch.rpm: Header V3 RSA/SHA256 Signature, key ID f4a80eb5: NOKEY
	Preparing...                          ################################# [100%]
	Updating / installing...
	   1:deltarpm-3.6-3.el7               ################################# [ 33%]
   	   2:python-deltarpm-3.6-3.el7        ################################# [ 67%]
   	   3:createrepo-0.9.9-23.el7          ################################# [100%]
	[root@r83x5u09 Packages]# pwd
	/mnt/centos7_64/Packages

## Create Repo
	cd /mnt
	sync --recursive --progress --archive --compress centos7_64 centos7_64_repo
	createrepo centos7_64_repo

## Create repo configuration    
[Sample repo files](yum_repos_d/)

	[root@r83x5u09 yum.repos.d]# cat /etc/yum.repos.d/centos7_fullpackage.repo
	[centos7_fullpackage]
	name=Extra Packages for Enterprise Linux 7 - $basearch
	baseurl=http://9.115.78.100/centos/7/x86_64/
	failovermethod=priority
	enabled=1
	gpgcheck=0
	priority=3
    

	[root@r83x5u09 yum.repos.d]# cat epel.repo
	[epel]
	name=Extra Packages for Enterprise Linux 7 - $basearch
	#baseurl=http://download.fedoraproject.org/pub/epel/7/$basearch
	mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch
	failovermethod=priority
	enabled=1
	gpgcheck=1
	gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
	proxy=http://9.115.78.100:8085/

	[epel-debuginfo]
	name=Extra Packages for Enterprise Linux 7 - $basearch - Debug
	#baseurl=http://download.fedoraproject.org/pub/epel/7/$basearch/debug
	mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-7&arch=$basearch
	failovermethod=priority
	enabled=0
	gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
	gpgcheck=1

	[epel-source]
	name=Extra Packages for Enterprise Linux 7 - $basearch - Source
	#baseurl=http://download.fedoraproject.org/pub/epel/7/SRPMS
	mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-source-7&arch=$basearch
	failovermethod=priority
	enabled=0
	gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
	gpgcheck=1

