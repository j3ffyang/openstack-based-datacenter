#!/bin/bash

usage()
{
cat << EOF

Usage: $0 <-u> <-r>
OPTIONS:
   -h      Show this message.
   -u      Provider a decibel build feed url.
   -r      Require a Region ip address ,install build address.
EOF
}

current_dir=`dirname $0 | xargs readlink -e`
FVT_FEED_URL=
REGION=

while getopts “h:u:r:” OPTION
do
     case $OPTION in
         h)
             usage
             exit -1
             ;;
         u)
             FVT_FEED_URL=$OPTARG
             ;;
         r)
             REGION=$OPTARG
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

if [ -z "${FVT_FEED_URL}" ] || [ -z "${REGION}" ]; then
        echo "ERROR: -u or -r options are required" 1>&2
        usage
        exit -1
fi

FEED_BUILD_ID=`${current_dir}/feedAnalyzer.py -u ${FVT_FEED_URL} -l /tmp/`

if [ -z "$FEED_BUILD_ID" ]
then
  echo "No valid production build found from fvt,wait for the next auto build."
  exit 1
fi
PACKAGE_FILE_NAME=IBM_Cloud_Orchestrator-2.4.0.0-${FEED_BUILD_ID}.tgz
BASE_URL="http://scbvt.rtp.raleigh.ibm.com/projects/s/scobvt/decibel-build/"
wget -N -e dotbytes=100M --tries=100 ${BASE_URL}/${FEED_BUILD_ID}/${PACKAGE_FILE_NAME} -O ${current_dir}/${PACKAGE_FILE_NAME}

PACKAGE_MD5=`md5sum ${current_dir}/IBM_Cloud_Orchestrator-2.4.0.0-${FEED_BUILD_ID}.tgz | awk '{print $1}'`
REGION_MD5=
ssh root@${REGION} "ls ${current_dir}/IBM_Cloud_Orchestrator-2.4.0.0-${FEED_BUILD_ID}.tgz"
CHECK_REGION=$?
if [ `echo ${CHECK_REGION}` -gt 0 ];then  
  scp ${current_dir}/IBM_Cloud_Orchestrator-2.4.0.0-${FEED_BUILD_ID}.tgz root@${REGION}:${current_dir}/
  REGION_MD5=`ssh root@${REGION} "md5sum ${current_dir}/IBM_Cloud_Orchestrator-2.4.0.0-${FEED_BUILD_ID}.tgz" | awk '{print $1}'`
else
  REGION_MD5=`ssh root@${REGION} "md5sum ${current_dir}/IBM_Cloud_Orchestrator-2.4.0.0-${FEED_BUILD_ID}.tgz" | awk '{print $1}'`
  if [ `echo ${PACKAGE_MD5}` != `echo ${REGION_MD5}` ];then
    scp ${current_dir}/IBM_Cloud_Orchestrator-2.4.0.0-${FEED_BUILD_ID}.tgz root@${REGION}:${current_dir}/
    REGION_MD5=`ssh root@${REGION} "md5sum ${current_dir}/IBM_Cloud_Orchestrator-2.4.0.0-${FEED_BUILD_ID}.tgz" | awk '{print $1}'`
    echo "Using latest build(${FEED_BUILD_ID}) to install region(${REGION})."
  else
    echo "You already to use the latest build(${FEED_BUILD_ID})."
    exit 0
  fi;
fi;

if [ `echo ${PACKAGE_MD5}` != `echo ${REGION_MD5}` ];then
  echo "The master package with region package md5sum is not match..."
  exit -1
fi;
