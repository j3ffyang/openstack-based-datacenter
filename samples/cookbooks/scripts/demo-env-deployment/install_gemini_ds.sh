#!/bin/bash
set -x 

#if [ -z "$1" ]
#then
#	echo USE $0 build ID
#	exit 99
#fi

basedir=`dirname $0 | xargs readlink -e`
source $basedir/deployment_service_Functions.sh

#echo "passw0rd" | passwd root --stdin
#rm -f /etc/yum.repos.d/*
#echo "INFO: installing pre-reqs"
#yum install -y openssh-clients

export http_proxy=http://9.115.78.100:8085/
export https_proxy=http://9.115.78.100:8085/
export BUILDID=`curl http://scbvt.rtp.raleigh.ibm.com/api/v1/results/bestproduction/d?short | grep id | cut -d':' -f 2 |  tr -d '"' | tr -d ' '`
#export BUILDID="D20140521-203703"
export SC_PWD=passw0rd
export OS_PWD=passw0rd
export DOWNLOAD_ROOT=$basedir/../builds/
#export DOWNLOAD_ROOT=/home/ico-pkgs/download/
export INSTALL_LOG=$basedir/../log/$BUILDID
export BASE_URL="http://scbvt.rtp.raleigh.ibm.com/projects/s/scobvt/decibel-build/"
export SCP_INSTALL_ROOT=$basedir/../install
#export SCO_INSTALL_DIR=/root/sco/scripts/../install/IBM_Cloud_Orchestrator-2.4.0.0-D20140219-174801/
export LOCK_DIR=$basedir/../lock
#export CENTRAL_SRV1_IP=$central1_addr
#if [ -f $basedir/../lock/lock ]; then
#	echo "There is a installation running on the machine !!"
#	exit 1
#fi

#clean deployment working directories
#rm -rf $DOWNLOAD_ROOT/*
#rm -rf $INSTALL_LOG/*

rm -rf $SCP_INSTALL_ROOT/*

CURRENT_BUILD=`cat /opt/ibm/cloud-deployer/ico.version | grep build_number | awk '{print $2}' | tr -d '"'`

if [ ! -z ${CURRENT_BUILD} ];then 
    if [ ${CURRENT_BUILD} == ${BUILDID} ];then
        echo "The current ds version with FVT version is consistent, does not need to upgrade."
        exit 0
    fi
fi

test -d $LOCK_DIR || mkdir -p $LOCK_DIR
test -d $INSTALL_LOG || mkdir -p $INSTALL_LOG
touch $LOCK_DIR/lock

installServiceServer
if [ "$?" -ne 0 ]; then
    echo "Did not install deployment-service correctly"
    exit 1
fi

rm -rf $DOWNLOAD_ROOT/*

#rm -f /usr/lib/python2.6/site-packages/dsclient/v1/shell.py
#cp /root/sco/scripts/shell.py /usr/lib/python2.6/site-packages/dsclient/v1/shell.py

#/etc/init.d/ds-engine restart
#sleep 5 
#/etc/init.d/ds-api restart
#sleep 5
#
#/etc/init.d/ds-api status | grep running > /dev/null 2>&1
#if [ $ -ne 0 ]; then
#    echo "ds-api service failed to start !"
#    cat /var/log/ds/ds-engine.log
#    exit 2
#fi
#
#/etc/init.d/ds-engine status | grep running > /dev/null 2>&1
#if [ $ -ne 0 ]; then
#    echo "ds-engine service failed to start !"
#    cat /var/log/ds/ds-engine.log
#    exit 3
#fi

source /root/keystonerc
ds job-list

cat /var/log/ds/ds-engine.log

exit 0

