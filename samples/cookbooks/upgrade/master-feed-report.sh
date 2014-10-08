#!/bin/bash

usage()
{
cat << EOF

Usage: $0 <-b> <-a> <-u> [-i]
          [-a <upgrade-inprogress, upgrade-failed, upgrade-passed>]
OPTIONS:
   -h      Show this message.
   -b      Provider a decibel build id.
   -a      Execute your action branch <upgrade-[status]>, fvttest>.
   -u      Provider a Gemini or FVT feed URL.
   -i      Provider ds ip address for fvt testing.
EOF
}

current_dir=`dirname $0 | xargs readlink -e`
BUILD_ID=
ACTION_TYPE=
URL=
IP=
DATE=`date +%s`

while getopts “h:b:a:u:i:” OPTION
do
     case $OPTION in
         h)
             usage
             exit -1
             ;;
         b)
             BUILD_ID=$OPTARG
             ;;
         a)
             ACTION_TYPE=$OPTARG
             ;;
         u)
             URL=$OPTARG
             ;;
         i)
             IP=$OPTARG
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

if [ -z "${BUILD_ID}" ] || [ -z "${ACTION_TYPE}" ] || [ -z "${URL}" ]; then
        echo "ERROR: -b or -a or -u options are required" 1>&2
        usage
        exit -1
fi

if [ "${ACTION_TYPE}" == "upgrade-failed" ];then
    curl -X POST -H "Content-Type: application/json" -d  \
    "{
        \"id\" : \"${BUILD_ID}\",
        \"date\" : ${DATE},
        \"personal\" : false,
        \"url\" : \"/builds/G${BUILD_ID}/\",
        \"status\" : \"Gemini upgrade failed\"  
    }"  ${URL}
elif [ "${ACTION_TYPE}" == "upgrade-passed" ];then
    curl -X POST -H "Content-Type: application/json" -d  \
    "{
        \"id\" : \"${BUILD_ID}\",
        \"date\" : ${DATE},
        \"personal\" : false,
        \"url\" : \"/builds/G${BUILD_ID}/\",
        \"status\" : \"Gemini upgrade passed\"  
    }"  ${URL}
elif [ "${ACTION_TYPE}" == "upgrade-inprogress" ];then
    CHECK_FEED_BUILD=`curl -s http://scbvt.rtp.raleigh.ibm.com/geminifeed/d?count=1000 | grep title | grep ${BUILD_ID}`
    if [ -z ${CHECK_FEED_BUILD#*>} ];then
        curl -X POST -H "Content-Type: application/json" -d  \
        "{
            \"id\" : \"${BUILD_ID}\",
            \"date\" : ${DATE},
            \"personal\" : false,
            \"url\" : \"/builds/G${BUILD_ID}/\",
            \"status\" : \"Gemini upgrade in progress\"  
        }"  ${URL}
    fi
elif [ "${ACTION_TYPE}" == "upgrade-inprogress" ];then
    curl -X POST -H "Content-Type: application/json" -d  \
    "{
        \"id\" : \"${BUILD_ID}\",
        \"date\" : ${DATE},
        \"personal\" : false,
        \"url\" : \"/builds/G${BUILD_ID}/\",
        \"status\" : \"Gemini upgrade in progress\"  
    }"  ${URL}
elif [ "${ACTION_TYPE}" == "fvttest" ];then
    STACK_NAME="P${BUILD_ID}${RANDOM}"
    FVT_RESULT=0
    if [ -z "${IP}" ]; then
        echo "ERROR: if you using fvttest -i option are required" 1>&2
        usage
        exit -1
    fi

    curl -X POST -H "Content-Type: application/json" -d    \
    "{
        \"action\" : \"excute\",
        \"ip\" : \"${IP}\",
        \"user\" : \"root\",
        \"passwd\" : \"passw0rd\",
        \"fvt_package_url\" : \"http://scbvt.rtp.raleigh.ibm.com/projects/s/scobvt/decibel-build/${BUILD_ID}/fvt.tgz\",
        \"topology\" : \"gemini\",
        \"stack_name\" : \"${STACK_NAME}\",
        \"build_id\" : \"G${BUILD_ID}\"
    }"  ${URL}
    echo ${BUILD_ID}
    FVT_RESULT=9
    while (($[`date +%s` - ${DATE}]<3600))
      do
        #FVTRESULT=`curl -s http://scbvt.rtp.raleigh.ibm.com/api/v1/results/G${BUILD_ID} |awk '/status/{print;exit}'`
        FVTRESULT=`curl -s http://scbvt.rtp.raleigh.ibm.com/api/v1/results/G${BUILD_ID}?short|grep -Po '(?<="status": ")[^"]*'`
        echo "status is $FVTRESULT"
        echo "$FVTRESULT" |grep -q "failed"
        if [ $? -eq 0 ];then
            FVT_RESULT=1
            break
        fi
        echo "$FVTRESULT" |grep -q "pass"
        if [ $? -eq 0 ];then
            FVT_RESULT=0
            break 
        fi
    sleep 60
    done
     
    echo "FVT result $FVT_RESULT"

    curl -X POST -H "Content-Type: application/json" -d    \
    "{
        \"action\" : \"delete\",
        \"stack_name\" : \"${STACK_NAME}\"
    }"  ${URL}

    exit ${FVT_RESULT}
fi
