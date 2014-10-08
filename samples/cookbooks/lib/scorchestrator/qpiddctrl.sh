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
# qpidd automation control scripts
#
# Input:	$1	Action ( <start|stop|restart|kill|status>, default: status )
#
# History:
#
#    14.04.14	initial version
#
##############################################################
SCRIPT_NAME=`basename $0`

#
# Action ( <start|stop|restart|kill|status>, default: status )
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
RUNNING_ON_AIX=0
KILL_CMD=/bin/kill

SERVICE_ID="qpidd"
CTRL_CMD="/sbin/service $SERVICE_ID"
SERVICE_CMD=/usr/sbin/qpidd

QPID_HA=/usr/bin/qpid-ha
QPID_CONF=/usr/bin/qpid-config
QPID_TIMEOUT=90

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

function start() {
  logit 0 "$SERVICE_ID start order issued."
  logit 0 "Stop it first."
  kill
  RC=0

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

function status() {
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
      # check if qpidd is available
      if [[ (-x $QPID_CONF) ]]; then
        addr=`grep "ha-public-url" /etc/qpidd.conf |cut -f 2 -d "="`
        logit 1 "qpidd public url: $addr"
        if [[ "X" = "X$addr" ]]; then
          addr="localhost"
        fi
        if timeout -s KILL $QPID_TIMEOUT $QPID_CONF -b $addr ; then
          logit 1 "qpidd is still in active"
          RC=${ONLINE}
        else
          logit 1 "qpidd has no response or no response"
          RC=${OFFLINE}
        fi
      else
         logit 1 "$QPID_CONF is not there"
      fi
    fi
  fi
  return ${RC}
}

function restart() {
  stop
  start
}

function kill() {
  PROCESS_ID=$($PS_CMD axwww|$GREP_CMD -v grep|$GREP_CMD "$SERVICE_CMD"|$AWK_CMD '{print $1}')
  if [ "$PROCESS_ID" != "" ]
  then
    logit 1 "Kill $SERVICE_CMD: $PROCESS_ID."
    OUT=$($KILL_CMD -9 $PROCESS_ID)
    RC=$?
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
    logit 0 "Error: Incorrect parameter >${Action}<"
    RC=${UNKNOWN}
    ;;
esac

exit ${RC}
