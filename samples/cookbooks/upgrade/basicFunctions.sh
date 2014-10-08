#!/bin/sh

# Log data
log() {
	echo "[`date --iso-8601=seconds`] $@"
}

# Capture the /proc/net/ data.  Pass in a string which is prepended to all log files
captureRouteInfo() {
	STAGE_NAME=${1}

	for device in route arp dev; do
		rm -f /tmp/${STAGE_NAME}.${device}.log
		cp /proc/net/${device} /tmp/${STAGE_NAME}.net.${device}.log
	done
}

# Load the cloud cloud configuration data from config file.
# The argrument should be the same as the script
initCloud() {
	local RET_VAL
	RET_VAL=0
	for i
	do
		CONFIG_FILE=${1}
		shift
		if [ ! -f "${CONFIG_FILE}" ]; then
		    echo "ERROR: The second argument to the script must be a config file to use"
		    RET_VAL=1
		else
		    echo "INFO: Using configuration file: ${CONFIG_FILE}"
		    source "${CONFIG_FILE}"
		fi
 	done
	export DOWNLOAD_ROOT=${DOWNLOAD_ROOT:-/opt}
	export SCP_INSTALL_ROOT=${SCP_INSTALL_ROOT:-$DOWNLOAD_ROOT/scp-installer}
	export RHEL_CD_NAME=${RHEL_CD_NAME:-RHEL6.3-20120613.2-Server-x86_64-DVD1.iso}
	export INSTALL_LOG=${INSTALL_LOG:-/root/scp-install/logs}
	if [ -z "$DEPLOY_TOPOLOGIES_ROOT" ]
	then
		if [ -z "$basedir" ]
		then
			basedir=`dirname $0 | xargs readlink -e`
		fi
		if [ -d "$basedir/../../topologies" ]
		then
			export DEPLOY_TOPOLOGIES_ROOT=`readlink -f $basedir/../..`
		elif [ -d "$basedir/../topologies" ]
		then
			export DEPLOY_TOPOLOGIES_ROOT=`readlink -f $basedir/..`
		fi
	fi
	# Check for build_server. On install systems that do not contain the
	# build images as well, the build server must be explicitly specified.
	if [ -z "$build_server" ]; then
	    log "INFO: The build_server variable was not set. Initialize to install_server."
	    export build_server=${install_server}
	fi
	return ${RET_VAL}
}
# make sure all the variables are there
#
checkVariables() {
	local RET_VAL
	RET_VAL=0
	if [ -z "$BUILDID" ]; then
	    log "ERROR: The config file must specify a BUILDID variable to specific which version should be installed"
	    RET_VAL=1
	fi
	# SHOULD Test without this
	if [ -z "$ftp3user" ] || [ -z "$ftp3pass" ]; then
	    log "ERROR: The ftp3user or ftp3pass options were missing from the config file"
	    RET_VAL=1
	fi


	if [ -z "$dns_suffix" ]; then
	    log "ERROR: The config file must specify a dns_suffix variable to specific which version should be installed"
	    RET_VAL=1
	fi

	if [ -z "$dhcp_range" ]; then
	    log "ERROR: The config file must specify a dhcp_range variable to specific which version should be installed"
	    RET_VAL=1
	fi

	if [ -z "$dns_servers" ]; then
	    log "ERROR: The config file must specify a dns_servers variable to specific which version should be installed"
	    RET_VAL=1
	fi

	if [ -z "$ntp_server" ]; then
	    log "ERROR: The config file must specify a ntp_server variable to specific which version should be installed"
	    RET_VAL=1
	fi
	if [ -z "$install_server" ]; then
	    log "ERROR: The config file must specify a install_server variable to specific which version should be installed"
	    RET_VAL=1
	fi

	return ${RET_VAL}
}

# make sure all the vmware variables are there
#
checkVMWareVariables() {
	local RET_VAL
	RET_VAL=0
	if [ -z "$VCENTER_HOST" ]; then
	    log "ERROR: The config file must specify a VCENTER_HOST variable to specific which version should be installed"
	    RET_VAL=1
	fi
	if [ -z "$VCENTER_USER" ]; then
	    log "ERROR: The config file must specify a VCENTER_USER variable to specific which version should be installed"
	    RET_VAL=1
	fi
	if [ -z "$VCENTER_PASSWORD" ]; then
	    log "ERROR: The config file must specify a VCENTER_PASSWORD variable to specific which version should be installed"
	    RET_VAL=1
	fi
	if [ -z "$VCENTER_NETWORK" ]; then
	    log "ERROR: The config file must specify a VCENTER_NETWORK variable to specific which version should be installed"
	    RET_VAL=1
	fi
	return ${RET_VAL}
}

# make sure all the vmcontrol variables are there
#
checkVMCVariables() {
	local RET_VAL
	RET_VAL=0
	if [ -z "$VMC_HOST" ]; then
	    log "ERROR: The config file must specify a VMC_HOST variable to specific which VMC host should be used"
	    RET_VAL=1
	fi
	if [ -z "$VMC_USER" ]; then
	    log "ERROR: The config file must specify a VMC_USER variable to specific which VMC user should be used"
	    RET_VAL=1
	fi
	if [ -z "$VMC_PASSWORD" ]; then
	    log "ERROR: The config file must specify a VMC_PASSWORD variable to specific which VMC password should be used"
	    RET_VAL=1
	fi
	if [ -z "$VMC_NETWORK" ]; then
	    log "ERROR: The config file must specify a VMC_NETWORK variable to specific what is the VMC network"
	    RET_VAL=1
	fi
	if [ -z "$LPAR_NETWORK" ]; then
	    log "ERROR: The config file must specify a LPAR_NETWORK variable to specific what is the LPAR network"
	    RET_VAL=1
	fi
	if [ -z "$VMC_SUBNET" ]; then
	    log "ERROR: The config file must specify a VMC_SUBNET variable to specific what is the VMC subnet"
	    RET_VAL=1
	fi
	if [ -z "$VMC_NETMASK" ]; then
	    log "ERROR: The config file must specify a VMC_NETMASK variable to specific what is the VMC netmask"
	    RET_VAL=1
	fi
	return ${RET_VAL}
}

# register this machine to get RHN update/packages
#
registerRHN() {
	log "Registering system with RH Network"
	wget -qO- --no-check-certificate https://rtp.rhn.linux.ibm.com/pub/bootstrap/bootstrap-rtp.sh | /bin/bash
	rhnreg_ks --use-eus-channel --force "--username=$ftp3user" "--password=$ftp3pass"
}

# fetching SCO dependenc, RHEL iso and rpms
fetchSCODependency() {
	test -d "${DOWNLOAD_ROOT}" || mkdir -p "${DOWNLOAD_ROOT}"
        test -d "${SCP_INSTALL_ROOT}" || mkdir -p "${SCP_INSTALL_ROOT}"
        log "Downloading red hat install"
        # downloading RHEL6.3 ISO
	# The Red hat cd iso name
        wget -e dotbytes=100M -c http://${build_server}/iso/${RHEL_CD_NAME} -O "${DOWNLOAD_ROOT}/${RHEL_CD_NAME}" || return 3
        log "Done downloading red hat install"
        # Fetch required RPMs, SHOULD NOT BE NEEDED
        log "Downloading required RPMS"
        mkdir -p /data/repos/scp
        pushd /data/repos/scp
        wget -e dotbytes=100M -nH --cut-dirs=5 -m ftp://bejgsa.ibm.com/projects/s/scp_ccs/installer_rpms/ || return 3
        popd
        log "Done downloading required RPMS"

}

fetchAndExtractOpenstack() {
	test -d "${DOWNLOAD_ROOT}" || mkdir -p "${DOWNLOAD_ROOT}"
        test -d "${SCP_INSTALL_ROOT}" || mkdir -p "${SCP_INSTALL_ROOT}"
	log "Getting Build: $BUILDID"

        log "Downloading openstack install"
       
        #scp   "root@$GEMINI_MASTER_IP:$PACKAGE_DOWNLOAD_DEST"    "${DOWNLOAD_ROOT}/IBM_SmartCloud_Orchestrator.tgz" || return 3
       # wget -e dotbytes=100M --tries=100 http://${build_server}/SCP_SCO_Installer/$BUILDID/IBM_SmartCloud_Orchestrator.tgz -O "${DOWNLOAD_ROOT}/IBM_SmartCloud_Orchestrator.tgz" || return 3
        log "Done downloading openstack"

        OPENSTACK_INSTALLER_NAME=IBM_SmartCloud_Installer_and_OpenStack-2.2.0.0-`echo $BUILDID | sed 's|-||g'`

        tar xzf ${DOWNLOAD_ROOT}/IBM_SmartCloud_Orchestrator.tgz -C "${SCP_INSTALL_ROOT}" "${OPENSTACK_INSTALLER_NAME}.tgz" || return 3

        log "Extracting openstack install"
        mkdir ${SCP_INSTALL_ROOT}
        tar xzf `find ${DOWNLOAD_ROOT} -name "IBM_SmartCloud_Installer_and_OpenStack-*.tgz"` -C "${SCP_INSTALL_ROOT}" || return 3
        log "Done extracting openstack install"

}

# just fetch and extract the openstack items and rhel cd
# RHEL6.3-20120613.2-Server-x86_64-DVD1.iso, IBM_SmartCloud_Installer_and_OpenStack-2.2.0.0
# extact the install to ${DOWNLOAD_ROOT}/scp-installer ( default /opt/scp-installer )
fetchAndExtractOpenstackBuildFiles() {
        fetchSCODependency || return $?
	fetchAndExtractOpenstack || return $?
}


# Fetch and extract the build files
# Currently fetching IBM_SmartCloud_Orchestrator.tgz
# extact the install to ${DOWNLOAD_ROOT}/scp-installer ( default /opt/scp-installer )
fetchAndExtractSCOBuildFiles() {

        log "Started extracting SCO installer"
        tar xzvf ${DOWNLOAD_ROOT}/IBM_SmartCloud_Orchestrator.tgz --exclude "${OPENSTACK_INSTALLER_NAME}.tgz" -C "${SCP_INSTALL_ROOT}" || return 3
        log "Finished extracting SCO installer"

        log "Done getting Build: $BUILDID"

}

# Fetch and extract the decibel build files
# extact the install to ${DOWNLOAD_ROOT}/scp-installer ( default /opt/scp-installer )
fetchAndExtractDecibelBuildFiles() {
        log "Downloading SCO install"
        PACKAGE_FILE_NAME=IBM_Cloud_Orchestrator-2.4.0.0-${BUILDID}.tgz
        #wget -e dotbytes=100M --tries=100 ${BASE_URL}/$BUILDID/${PACKAGE_FILE_NAME} -O "${DOWNLOAD_ROOT}/${PACKAGE_FILE_NAME}" || return 3
        log "Done downloading SCO install"
        log "Started extracting SCO installer"
        test -d "${SCP_INSTALL_ROOT}" || mkdir -p "${SCP_INSTALL_ROOT}"
        tar -xvf ${DOWNLOAD_ROOT}/${PACKAGE_FILE_NAME} -C "${SCP_INSTALL_ROOT}" || return 3
        log "Finished extracting SCO installer"
        export SCO_INSTALL_DIR=`find ${SCP_INSTALL_ROOT} -type d -name "IBM_Cloud_Orchestrator-*" | head -n 1`
        log "Done getting Build: $BUILDID"

}

# set the iscp configuration setting
# ISCP_CONFIG needs to be set
# argurements are: Setting Value
setISCPConfigSettings() {
	setConfig "${ISCP_CONFIG}" "$@"

}

# Set the ISCP config file
# some varibles are pull from the enviroments
setISCPConfig() {
	if [ -z "${ISCP_CONFIG}" ]
	then
		ISCP_CONFIG=`find ${SCP_INSTALL_ROOT} -type d -name "IBM_SmartCloud_Installer_and_OpenStack-*" | head -n 1`
		ISCP_CONFIG=${ISCP_CONFIG}/ISCP.cfg
	fi
	echo "# Configuration changes for install test" >>  $ISCP_CONFIG


	# Explicitly set the ISO location
	setISCPConfigSettings "iso_location" "${DOWNLOAD_ROOT}/${RHEL_CD_NAME}" || return 78

	# Update DNS suffix to be rtp.raleigh.ibm.com
	setISCPConfigSettings "dns_suffix" "$dns_suffix" || return 78

	# Include DHCP range
	setISCPConfigSettings "dhcp_range" "$dhcp_range" || return 78

	if [ ! -z "$gateway" ]; then
		setISCPConfigSettings "gateway" "$gateway" || return 78
	fi

	# Set managment_network_device to 'eth0'
	setISCPConfigSettings "managment_network_device" "${managment_network_device:-eth0}" || return 78

	# Set dns_world to 9.0.6.1
	setISCPConfigSettings "dns_world" "$dns_servers" || return 78

	# Set ntp_svr_addrs to rtpgsa.ibm.com
	setISCPConfigSettings "ntp_svr_addrs" "$ntp_server" || return 78

	# Maybe enable SCE during install
	setISCPConfigSettings "all_in_one_smartcloud" "${enable_sce:-no}" || return 78
}

# prepare the install machine for install sco
prepareInstall() {
	registerRHN
	# configuring the time
	log "Installing ntp"
	yum install -y ntp
	ntpdate $ntp_server
	/sbin/service ntpd start
	/sbin/chkconfig ntpd on
	# Disable selinux on next reboot
	sed -i 's|SELINUX=enforcing|SELINUX=disabled|' /etc/selinux/config
	# Temporarily disable it until the next reboot
	echo 0 > /selinux/enforce
	mkdir -p "${INSTALL_LOG}"
	prepLibvirtd
	if [ "$?" -ne "0" ]; then log "Could not prereq libvirt"; return 3; fi
}

# just install the openstack version of sco
installOpenstack() {
	log "Starting firstbox_run"
	if [ -z "${SCO_OPENSTACK_INSTALL}" ]
	then
		SCO_OPENSTACK_INSTALL=`find "${SCP_INSTALL_ROOT}" -type d -name "IBM_SmartCloud_Installer_and_OpenStack-*" | head -n 1`
	fi
	${SCO_OPENSTACK_INSTALL}/firstbox_run -s i < /dev/null > ${INSTALL_LOG}/firstbox_output.log 2>&1
	FIRSTBOX_RESULT=$?
	if [ "0" == "$FIRSTBOX_RESULT" ]; then
	  log "firstbox_run completed successfully"
	else
	  log "firstbox_run completed with error $FIRSTBOX_RESULT"
	  return 12
	fi
	log "Starting allinone/install.sh"

	${SCO_OPENSTACK_INSTALL}/deploy-scripts/allinone/install.sh -a passw0rd -r passw0rd < /dev/null > ${INSTALL_LOG}/allinone-install.log 2>&1
	INSTALL_RESULT=$?
	if [ "0" == "$INSTALL_RESULT" ]; then
	  log "allinone/install.sh completed successfully"
	else
	  log "allinone/install.sh completed with error $INSTALL_RESULT"
	  return 13
	fi
}

prepLibvirtd() {
	# Make sure libvirtd will start, SHOULD NOT BE NEEDED
	yum install -y libvirt
	if [ "$?" -ne "0" ]; then log "Could not install libvirt"; return 3; fi
	# In /etc/libvirt/libvirtd.conf make sure that "mdns_adv = 0" is included
	sed -i 's|^#mdns_adv\(\s*\)=\(\s*\)0|mdns_adv\1=\20|' /etc/libvirt/libvirtd.conf

	# SHOULD NOT BE NEEDED
	modprobe kvm-amd > /dev/null 2>&1 || modprobe kvm-intel  > /dev/null 2>&1
	if [ "$?" != "0" ]; then
	  log "Both kvm-intel or kvm-amd failed to load, but one is needed"
	  return 1
	fi
	# Should not be needed
	chown root:kvm /dev/kvm

	# Should not be needed
	service libvirtd start

	return 0
}

# install sco download the files, and run the 3 install scripts

installSCO() {
	cp -av /root/.ssh/authorized_keys /root/authorized_keys.orig
	log "Configuring system for SCP prereqs"

	captureRouteInfo "prepareInstall"
	prepareInstall
	if [ "$?" -ne "0" ]; then log "Could not prep install"; return 3; fi

	# fetching builds
	fetchAndExtractOpenstackBuildFiles
	if [ "$?" -ne "0" ]; then log "Could not extract openstack"; return 3; fi

	fetchAndExtractSCOBuildFiles
	if [ "$?" -ne "0" ]; then log "Could not extract sco"; return 3; fi

	if [ -z "${SCO_OPENSTACK_INSTALL}" ]
	then
		SCO_OPENSTACK_INSTALL=`find "${SCP_INSTALL_ROOT}" -type d -name "IBM_SmartCloud_Installer_and_OpenStack-*" | head -n 1`
	fi

	# configuring ISCP
	setISCPConfig
	if [ "$?" != "0" ]; then
	  log "Could not setup the ISCP config file"
	  return 1
	fi
	captureRouteInfo "installOpenstack"
	installOpenstack
	if [ "$?" -ne "0" ]; then log "Could not install openstack"; return 3; fi

	captureRouteInfo "deploy_all"
	log "Started deploy_all.sh"
	pushd ${SCO_OPENSTACK_INSTALL}/inst-scripts/
	./deploy_all.sh < /dev/null > ${INSTALL_LOG}/deploy_all.sh 2>&1
	DEPLOY_RESULT=$?
	popd

	if [ "0" == "$DEPLOY_RESULT" ]; then
	  log "Finished deploy_all.sh successfully"
	else
	  log "Finished deploy_all.sh with error $DEPLOY_RESULT"
	  return 14
	fi
	cat /root/authorized_keys.orig >> /root/.ssh/authorized_keys

	captureRouteInfo "InstallComplete"
}

# get configuration settings
# arguments: configFile setting "default value"
getConfig() {
	local RET_VAL
	RET_VAL=1
	local CONFIG_FILE
	CONFIG_FILE=$1
	shift
	local SETTINGS
	SETTINGS=$1
	shift
	local VALUE
	VALUE=$1
	shift
	if [ -f "$CONFIG_FILE" ]
	then
		SETTING_LINE=`egrep '^'${SETTINGS}' *=.*$' $CONFIG_FILE`
		if [ "$?" -eq 0 ]
		then
			VALUE=`echo $SETTING_LINE | sed 's|.*= *\([^ ]*\) *$|\1|'`
		fi

		RET_VAL=0
	else
		RET_VAL=99
	fi
	echo $VALUE
	return $RET_VAL
}
# set a configuration settings, config file format settings=value
# arguement: ConfigFile Settings Value
setConfig() {
	local RET_VAL
	RET_VAL=1
	local CONFIG_FILE
	CONFIG_FILE=$1
	echo $CONFIG_FILE
	shift
	local SETTINGS
	SETTINGS=$1
	shift
	local VALUE
	VALUE=$1
	shift
	if [ -f "$CONFIG_FILE" ]
	then
		sed -i 's|^'${SETTINGS}'\( *\)=\(.*\)$|#'${SETTINGS}'\1=\2|g' $CONFIG_FILE
		echo "${SETTINGS}=${VALUE}" >> $CONFIG_FILE
		RET_VAL=0
	else
		RET_VAL=99
	fi
	return $RET_VAL
}
# set a settings in the nova.conf file
setNovaConfig() {
	setConfig /etc/nova/nova.conf "$@"
}
# connect the system to a vmware cloud
# SCO needs to already be installed, with sce enabled
# pull information from enviroement variables
setupVMWare() {
	source ~/keystonerc
	/opt/ibm/openstack/iaas/smartcloud/bin/nova-cloud-create "`hostname`" vmware "$VCENTER_HOST" "$VCENTER_USER" "$VCENTER_PASSWORD" VMware
	if [ "$?" -ne "0" ]; then log "Could not connect vmware cloud"; return 3; fi
	/opt/ibm/openstack/iaas/smartcloud/bin/nova-netext-match vmware "$VCENTER_NETWORK" "`nova-manage network list | tail -n +2 | head -n 1 | cut -f 9`"
	if [ "$?" -ne "0" ]; then log "Could not match network"; return 3; fi

	#restart IWD to make sure the cloud group is rediscovered
	ssh kersrv-2 "service iwd restart"
}

# connect the system to a VMControl cloud
# SCO needs to already be installed, with sce enabled
# pull information from enviroement variables
setupVMControl() {
	source ~/keystonerc
	#create vmcontrol network
	nova-manage network create --fixed_range_v4 172.16.22.0/24 --gateway 172.16.22.1 --dns1 172.17.40.192 --label vmcnet --fixed_cidr $LPAR_NETWORK --bridge br4090
	if [ "$?" -ne "0" ]; then log "Could not create network"; return 3; fi
	sleep 10

	/opt/ibm/openstack/iaas/smartcloud/bin/nova-cloud-create "`hostname`" vmcontrol "$VMC_HOST" "$VMC_USER" "$VMC_PASSWORD" VMControl
        if [ "$?" -ne "0" ]; then log "Could not connect VMControl cloud"; return 3; fi
        
        local count=1
  		while [[ $count < 60 ]]; do
    	/opt/ibm/openstack/iaas/smartcloud/bin/nova-netext-show vmcontrol | grep "$VMC_NETWORK" &>/dev/null
    	[ $? -ne 0 ] && echo "Error! Cannot find the network name ${VMC_NETWORK} in vmcontrol $count times." >&2 || break
    	let count=$count+1
    	sleep 30
  		done
        
        /opt/ibm/openstack/iaas/smartcloud/bin/nova-netext-match vmcontrol "$VMC_NETWORK" "`nova-manage network list | tail -n +3 | head -n 1 | cut -f 9`"
        if [ "$?" -ne "0" ]; then log "Could not match network"; return 3; fi
        
        #restart IWD to make sure the cloud group is rediscovered
    	ssh kersrv-2 "service iwd restart"
}

# restart all the nova compute services
restartNova() {
	RET_VAL=0
	for i in openstack-nova-api openstack-nova-cert openstack-nova-network openstack-nova-scheduler
	do
		service $i restart || RET_VAL=$?
	done
	return $RET_VAL
}

# restart all the cinder services
restartCinder() {
	RET_VAL=0
	for i in openstack-cinder-api openstack-cinder-scheduler openstack-cinder-volume
	do
		service $i restart || RET_VAL=$?
	done
	return $RET_VAL
}

# restart all the glance services
restartGlance() {
	RET_VAL=0
	for i in openstack-glance-api openstack-glance-registry
	do
		service $i restart || RET_VAL=$?
	done
	return $RET_VAL
}

# get server ip address
getIPFromHostname() {
	HOSTNAME_IN=${1}
	shift
	getent hosts ${HOSTNAME_IN} | cut -d ' ' -f 1
}


# disable all the quotas via the nova.conf
disableQuotas() {
	for i in quota_instances quota_cores quota_ram
	do
		setNovaConfig $i -1
	done
	restartNova
}

# uninstall sco services before upgrading
uninstallSCO() {
	#/etc/init.d/dnsmasq stop
	source /root/keystonerc
	#heat stack-list|grep gemini-allinone || return $?
	RET_VAL=0
	> /var/log/ds/ds-engine.log
	> /home/heat/.ssh/known_hosts
	#> ~/.ssh/authorized_keys
	heat delete gemini-allinone
	knife node delete allinone -y -c /etc/chef/knife.rb
	knife client delete allinone -y -c /etc/chef/knife.rb 
	sleep 10
	heat stack-list|grep gemini-allinone || RET_VAL=$?
	if [ "$RET_VAL" != 0 ]; then
		for i in `keystone service-list|grep Service|awk '{print $2}'`; do keystone service-delete $i; done		
		for i in `keystone endpoint-list|grep http|awk '{print $2}'`;do keystone endpoint-delete $i; done
	fi
	/etc/init.d/dnsmasq stop
	> /root/keystonerc
	return $RET_VAL
}

