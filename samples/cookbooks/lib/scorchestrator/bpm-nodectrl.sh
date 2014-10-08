#!/bin/bash
##################################################################################################
# Licensed Materials - Property of IBM Copyright IBM Corporation 2013. All Rights Reserved.      #
# U.S. Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP #
# Schedule Contract with IBM Corp.                                                               #
##################################################################################################
#################################################################################
#		                                                   		        		#
# bpm-node control script, delegate the bpm-node service						#		
#																				#
# Author: Hoang-Anh Le [hoang at de dot ibm dot com]               			 	#
#															    			 	#
# Input:	$1	Action ( <start|stop|status|restart|kill|help>, default: help ) #
#			 																 	#				
# History:														 			 	#
#																			 	#
# 	19.08.13	initial version												 	#
#																			 	#
#################################################################################
SCRIPT_NAME=`basename $0`

#
# Action ( <start|stop|status|restart|kill|help>, default: help )
#
Action=${1:-help}

#
# DEBUG - specify the amount of data written to /var/log/messages
#
DEBUG=1

#
# init section 
#

#
# Return codes
#
UNKNOWN=0
ONLINE=1
OFFLINE=2
FAILED_OFFLINE=3
STUCK_ONLINE=4
PENDING_ONLINE=5
PENDING_OFFLINE=6

#
# Commands
#
LOGGER_CMD=/usr/bin/logger
RUNNING_ON_AIX=0

SERVICE_ID="bpm-node"

# logit function
# $1: Log level
# $2: MSG ID
# $3-$n: Args 
function logit {
	level=$1
	shift 1; # shift first argument: level
	if [[ ${DEBUG} -ge ${level} ]]; then
    	msg=$@ # get message
    	if [[ $RUNNING_ON_AIX -eq 0 ]]; then
    		logger -s "$SCRIPT_NAME ($$): ${msg}"
    	else
    		$LOGGER_CMD -p user.debug -i "$SCRIPT_NAME: ${msg}"
    	fi
	fi
}

#
# main functions
#

# HELP
function help(){
	logit 0 "::: ./bpm-nodectrl.sh [start|stop|status|restart|kill|help]" 
}

# START
function start(){
	RC=0
	service $SERVICE_ID start
	RC=$?
	return ${RC}
}

# STOP
function stop(){
	RC=0
	service $SERVICE_ID stop
	RC=$?
	return ${RC}
}

# RESTART
function restart(){
	stop
	start
}

# STATUS
function status(){
	RC=0
	service $SERVICE_ID status
	RC=$?
	return ${RC}
}

# KILL
function kill(){
	RC=0
	service $SERVICE_ID kill
	RC=$?
	return ${RC}
}



#
# main section
#
case ${Action} in
	start|stop|status|restart|kill|help)
    ${Action}
    RC=$?
    ;;
	*) # incorrect input -->> log & exit
	  logit 0 "::: Error: Incorrect parameter >${Action}<"
	  RC=${UNKNOWN}
	  ;;
esac

exit ${RC}