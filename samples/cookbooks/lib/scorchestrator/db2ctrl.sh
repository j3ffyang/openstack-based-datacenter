#!/bin/sh
# IBM_PROLOG_BEGIN_TAG 
# This is an automatically generated prolog. 
#  
#  
#  
# Licensed Materials - Property of IBM 
#  
# (C) COPYRIGHT International Business Machines Corp. 2013
# All Rights Reserved 
#  
# US Government Users Restricted Rights - Use, duplication or 
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp. 
#  
# IBM_PROLOG_END_TAG 
##############################################################
#
# sco automation control scripts
#
# Input:	$1	Action ( <start|stop|status>, default: status )
#
# History:
#
#    14.04.13	initial version
#
##############################################################
SCRIPT_NAME=`basename $0`

#
# Action ( <start|stop|status>, default: status )
#
Action=${1:-status}

#
# DEBUG - specify the amount of data written to /var/log/messages
#
DEBUG=1

#
# init section 
#
UNKNOWN=0
ONLINE=1
OFFLINE=2
FAILED_OFFLINE=3
STUCK_ONLINE=4
PENDING_ONLINE=5
PENDING_OFFLINE=6

HOSTNAME_CMD=/bin/hostname
GREP_CMD=/bin/grep
PS_CMD=/bin/ps
SED_CMD=/bin/sed
AWK_CMD=/bin/awk
RM_CMD=/bin/rm
TR_CMD=/usr/bin/tr
ECHO_CMD=/bin/echo
WC_CMD=/usr/bin/wc
NETSTAT_CMD=/bin/netstat
LSOF_CMD=/usr/sbin/lsof
KILL_CMD=/bin/kill
RUNNING_ON_AIX=0

SERVICE_ID="DB2"

# logit function
# $1: Log level
# $2: MSG ID
# $3-$n: Args 
function logit {

  level=$1

  # shift first argument: level
  shift 1;

  if [[ ${DEBUG} -ge ${level} ]]; then
    # get message
    msg=$@

    if [[ $RUNNING_ON_AIX -eq 0 ]]; then
      logger -s "$SCRIPT_NAME ($$): ${msg}"
    else
      /usr/bin/logger -p user.debug -i "$SCRIPT_NAME: ${msg}"
    fi
  fi
}

#
# main section
#
case ${Action} in
  start)
    RC=0
    logit 0 "$SERVICE_ID start order issued."
    OUT=$(su - db2inst1 -c "db2start 2>&1")
    RC=$?
    logit 0 "$SERVICE_ID start done. RC:$RC STDOUT: $OUT"
	if [ $RC = 1 ]
	then
	   ALREADYSTARTED=$(echo $OUT | $GREP_CMD "SQL1026N")
	   if [ "$ALREADYSTARTED" != "" ]
	   then
	      RC=0
	   fi
	fi
    ;;
  stop)
    RC=0
    logit 0 "$SERVICE_ID stop order issued."
    OUT=$(su - db2inst1 -c "db2 force application all; db2 terminate; db2stop force 2>&1")
    RC=$?
    logit 0 "$SERVICE_ID stop done. RC:$RC STDOUT: $OUT"
	if [ $RC = 1 ]
	then
	   ALREADYSTOPPED=$(echo $OUT | $GREP_CMD "SQL1032N")
	   if [ "$ALREADYSTOPPED" != "" ]
	   then
	      RC=0
	   fi
	fi
    ;;
  status)
    STOP_RUNNING=$($PS_CMD axwww|$GREP_CMD -v grep|$GREP_CMD "$SCRIPT_NAME stop")
    START_RUNNING=$($PS_CMD axwww|$GREP_CMD -v grep|$GREP_CMD "$SCRIPT_NAME start")
    if [ "$STOP_RUNNING" != "" ]
    then
       logit 1 "$SERVICE_ID stop still running."
       RC=$PENDING_OFFLINE
    elif [ "$START_RUNNING" != "" ]
    then
       logit 1 "$SERVICE_ID start still running."
       RC=$PENDING_ONLINE
    else
      # check RUNNING
	RUNNING=$($PS_CMD -ef 2>&1|$GREP_CMD db2sysc|$GREP_CMD -v grep|$WC_CMD -l)
	if [[ $RUNNING -ne 0 ]]; then
	  logit 1 "$SERVICE_ID status monitor detected $SERVICE_ID online."
	  RC=${ONLINE}
	else
	  logit 1 "$SERVICE_ID status monitor detected $SERVICE_ID offline."
	  RC=${OFFLINE}
	fi
fi
    ;;
 kill)
    db2PID=`$PS_CMD -ef | $GREP_CMD db2sysc | $GREP_CMD -v grep | $AWK_CMD '{print $2}' `
    if [ -z "$db2PID" ]
    then
        logit 1 "$SERVICE_ID already stopped"
        RC=0
    else
        $KILL_CMD -9 $db2PID
        RC=$?
        if [ $RC -ne 0 ]
        then
            logit 1 "Failed to kill $SERVICE_ID"
        else
            logit 1 "$SERVICE_ID killed at (time in UTC): `date -u` ************"

        fi
    fi
    ;; 
  *) # incorrect input -->> log & exit
    logit 0 "Error: Incorrect parameter >${Action}<"
    RC=${UNKNOWN}
    ;;
esac

exit ${RC}
