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
# openstack service automation control scripts
#
# Input:	$1	service name
# Input:	$2	Action ( <start|stop|restart|kill|status>, default: status )
#
# History:
#
#    14.04.14	initial version
#
##############################################################
SCRIPT_NAME=`basename $0`

SERVICE_ID=$1
#
# Action ( <start|stop|restart|kill|status>, default: status )
#
Action=${2:-status}

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
RUNNING_ON_AIX=0
KILL_CMD=/bin/kill
KILLALL_CMD=/usr/bin/killall

CTRL_CMD="/sbin/service $SERVICE_ID"

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
      /usr/bin/logger -p user.debug -i "$SCRIPT_NAME ($SERVICE_ID): ${msg}"
    fi
  fi
}

function start() {
  RC=0
  logit 0 "$SERVICE_ID start order issued."
  OUT=$($CTRL_CMD start 2>&1|$SED_CMD "s/\..*\[.*OK.*\].*$/OK/"|$SED_CMD "s/\..*\[.*FAILED.*\].*$/FAILED/"|$TR_CMD '\n' ' ')
  logit 0 "$SERVICE_ID start done. RC:$RC STDOUT: $OUT"
  if [[ $($ECHO_CMD $OUT|$GREP_CMD FAILED) != "" ]]; then
    RC=1
    break
  fi
  return ${RC}
}

function stop() {
  RC=0
  logit 0 "$SERVICE_ID stop order issued."
  OUT=$($CTRL_CMD stop 2>&1|$SED_CMD "s/\..*\[.*OK.*\].*$/OK/"|$SED_CMD "s/\..*\[.*FAILED.*\].*$/FAILED/"|$TR_CMD '\n' ' ')
  logit 0 "$SERVICE_ID stop done. RC:$RC STDOUT: $OUT"
  if [[ $($ECHO_CMD $OUT|$GREP_CMD FAILED) != "" ]]; then
    RC=1
    break
  fi
  max_retries=6
  retries=0
  while [[ $retries -lt $max_retries ]]
  do
    RUNNING=$($CTRL_CMD status 2>&1|$GREP_CMD -i RUNNING|$WC_CMD -l)
    if [[ $RUNNING -eq 0 ]]; then
      break
    fi
    retries=$((${retries}+1))
    if [[ $retries -eq $max_retries ]]; then
      RC=1
      break
    fi
    /bin/sleep 5
  done
  return ${RC}
}

function restart() {
  stop
  start
}

function status() {
  STOP_RUNNING=$($PS_CMD axwww|$GREP_CMD -v grep|$GREP_CMD "$SCRIPT_NAME $SERVICE_ID stop")
  START_RUNNING=$($PS_CMD axwww|$GREP_CMD -v grep|$GREP_CMD "$SCRIPT_NAME $SERVICE_ID start")
  if [ "$STOP_RUNNING" != "" ]
  then
    logit 1 "$SERVICE_ID stop still running."
    RC=$PENDING_OFFLINE
  elif [ "$START_RUNNING" != "" ]
  then
    logit 1 "$SERVICE_ID start still running."
    RC=$PENDING_ONLINE
  else
    OUT=$($CTRL_CMD status 2>&1)
    RC=$?
    if [[ "X$RC" != "X0" ]]; then
      # service returned rc != 0
      logit 0 "$SERVICE_ID status monitor failed. RC:$RC STDOUT: $OUT"
      RC=${OFFLINE}
    else
      # check RUNNING
      RUNNING=$($CTRL_CMD status 2>&1|$GREP_CMD -i RUNNING|$WC_CMD -l)
      if [[ $RUNNING -ne 0 ]]; then
        logit 1 "$SERVICE_ID status monitor detected $SERVICE_ID online."
        RC=${ONLINE}
      else
        logit 1 "$SERVICE_ID status monitor detected $SERVICE_ID offline."
        RC=${OFFLINE}
      fi
    fi
  fi
  return ${RC}
}

function kill() {
  SERVICE_CMD=$($ECHO_CMD $SERVICE_ID | $SED_CMD 's/openstack-\(.*\)/\1/g')
  logit 1 "Trying to kill $SERVICE_CMD"
  PROCESS_ID=$($PS_CMD axwww|$GREP_CMD -v grep|$GREP_CMD python |$GREP_CMD "$SERVICE_CMD" |$AWK_CMD '{print $1}')
  if [[ "$PROCESS_ID" != "" ]]
  then
    for i in $PROCESS_ID
    do
      # make sure the process is still running
      IS_RUNNING=$($PS_CMD -ap $i |$GREP_CMD $SERVICE_CMD)
      if [[ "$IS_RUNNING" != "" ]]
      then
        logit 1 "Kill $SERVICE_CMD: $i."
        OUT=$($KILL_CMD -9 $i)
        RC=$?
      fi
    done
    # for nova network, also need kill dnsmasq
    if [[ "$SERVICE_ID" == "openstack-nova-network" ]]
    then
      $KILLALL_CMD -9 dnsmasq
    fi
    RC=0
  else
    logit 1 "Fail to get $SERVICE_CMD process id, can not kill it."
    RC=1
  fi
  return ${RC}
}

#
# main section
#
case ${Action} in
  start|stop|status|restart|kill)
    ${Action}
    RC=$?
    ;;
  *) # incorrect input -->> log & exit
    logit 0 "Error: Incorrect parameter >${Action}< \n Usage: $SCRIPT_NAME <service name> <start|stop|restart|kill|status>"
    RC=${UNKNOWN}
    ;;
esac

exit ${RC}
