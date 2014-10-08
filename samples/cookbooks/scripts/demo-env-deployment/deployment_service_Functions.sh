#!/bin/sh

basedir=`dirname $0 | xargs readlink -e`
source $basedir/basicFunctions.sh

installServiceServer() {
	log "install deployment-service"
	prepareServer
	if [ "$?" -ne "0" ]; then log "Could not prep server"; return 3; fi

	fetchAndExtractDecibelBuildFiles
	if [ "$?" -ne "0" ]; then log "Could not extract sco"; return 3; fi

	# configuring SCO
	setServiceServerConfig
	if [ "$?" != "0" ]; then
	  log "Could not setup the deployment-service config file"
	  return 1
	fi

	captureRouteInfo "deployServiceServer"
	
	log "remove /root/.ssh/known_hosts"
	rm -f /root/.ssh/known_hosts
	
	log "Started deployment_service.sh"
	pushd ${SCO_INSTALL_DIR}/installer/
	unset http_proxy
	unset https_proxy
	yum clean all
	sleep 5
	./deploy_deployment_service.sh -a -S $OS_PWD < /dev/null > ${INSTALL_LOG}/deploy_deployment_service.log 2>&1
	DEPLOY_RESULT=$?
	popd

	if [ "0" == "$DEPLOY_RESULT" ]; then
	  log "Finished deploy_deployment_service.sh successfully"
	else
	  log "Finished deploy_deployment_service.sh with error $DEPLOY_RESULT"
	  return 14
	fi
	captureRouteInfo "deployServiceComplete"
}

# prepare the install machine for install sco
prepareServer() {
#	uninstallSCO
	test -d "${INSTALL_LOG}" || mkdir -p "${INSTALL_LOG}"
}

setServiceServerConfig() {
	if [ -z "${DEPLOYMENT_CONFIG}" ]
	then
		DEPLOYMENT_CONFIG=${SCO_INSTALL_DIR}/installer/deployment-service.cfg
	fi
	
	# defined in vm template
	export managment_network_device="eth0"
	#export iso_location="/opt/RHEL6.4-20130130.0-Server-x86_64-DVD1.iso"
	export iso_location="/root/sco/RHEL6.5-20131111.0-Server-x86_64-DVD1.iso"
	echo "setConfig to ${ALLINONE_CONFIG}"
	# add line break to avoid missing line break in the end
	echo "">>${ALLINONE_CONFIG}
	setConfig ${DEPLOYMENT_CONFIG} managment_network_device $managment_network_device
	setConfig ${DEPLOYMENT_CONFIG} iso_location $iso_location
}
