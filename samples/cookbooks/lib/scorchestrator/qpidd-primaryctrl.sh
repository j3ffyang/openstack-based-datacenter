#!/bin/bash
#
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

# Description: Qpidd can be run in an active/passive cluster. Promote a running qpidd to primary.

prog=qpidd

# Source function library.
. /etc/rc.d/init.d/functions

if [ -f /etc/sysconfig/$prog ] ; then
    . /etc/sysconfig/$prog
fi

# The following variables can be overridden in /etc/sysconfig/$prog
[[ $QPID_PORT ]] || QPID_PORT=5672
[[ $QPID_HA ]]   || QPID_HA=/usr/bin/qpid-ha
export QPID_PORT

QPID_CONF=/usr/bin/qpid-config

RETVAL=0

SERVICE_CMD=/sbin/service

#ensure binary is present and executable
if [[ !(-x $QPID_HA) ]]; then
    echo "qpid-ha executable not found or not executable"
fi

status() {
    if $QPID_HA -b localhost:$QPID_PORT status --expect=active ; then
	echo "qpidd is primary"
        return 1
    else
	echo "qpidd is not primary"
	return 2
    fi
}

start() {
    $SERVICE_CMD qpidd start
    echo -n $"Promoting qpid daemon to cluster primary: "
    $QPID_HA -b localhost:$QPID_PORT promote
    [ "$?" -eq 0 ] && success || failure
}

stop() {
    $SERVICE_CMD qpidd stop
}

reload() {
    echo 1>&2 $"$0: reload not supported"
    exit 3
}

restart() {
    $SERVICE_CMD qpidd restart && start
}

# See how we were called.
case "$1" in
    start|stop|status|restart|reload)
	$1
	RETVAL=$?
	;;
    force-reload)
	restart
	;;
    *)
	echo 1>&2 $"Usage: $0 {start|stop|status|restart|force-reload}"
	exit 2
esac

exit $RETVAL
