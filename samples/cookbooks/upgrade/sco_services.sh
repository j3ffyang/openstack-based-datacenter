#!/bin/bash

usage()
{
cat << EOF
start, stop and provide status of SCO services. This script should be run on any servers in overcloud
Usage: $0 <-a>
OPTIONS:
   -h      Show this message.
   -a      action name, valid options: start|stop|status
EOF
}

current_dir=`dirname $0 | xargs readlink -e`
ACTION="status"
while getopts “ha:” OPTION
do
     case $OPTION in
         h)
             usage
             exit -1
             ;;
         a)
             ACTION=$OPTARG
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

${current_dir}/../lib/scorchestrator/SCOrchestrator.py --${ACTION} -c ${current_dir}/../lib/scorchestrator/GeminiComponents.xml -e ${current_dir}/../lib/scorchestrator/GeminiEnvironment.xml
