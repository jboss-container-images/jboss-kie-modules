#!/bin/sh

. "$JBOSS_HOME/bin/probe_common.sh"

if [ true = "${DEBUG}" ] ; then
    # short circuit liveness check in dev mode
    exit 0
fi

OUTPUT=/tmp/readiness-output
ERROR=/tmp/readiness-error
LOG=/tmp/readiness-log

CURL_OUTPUT=/tmp/liveness-kie-output
CURL_ERROR=/tmp/liveness-kie-error
KIE_SERVER_URL=http://${KIE_SERVER_HOST}:8080/services/rest/server/

COUNT=30
SLEEP=5
DEBUG=false
PROBE_IMPL=probe.eap.dmr.EapProbe

if [ $# -gt 0 ] ; then
    COUNT=$1
fi

if [ $# -gt 1 ] ; then
    SLEEP=$2
fi

if [ $# -gt 2 ] ; then
    DEBUG=$3
fi

if [ $# -gt 3 ] ; then
    PROBE_IMPL=$4
fi

if [ "$DEBUG" = "true" ]; then
    DEBUG_OPTIONS="--debug --logfile $LOG --loglevel DEBUG"
fi

#Curl the kie service to check for errors
curl -s -L -k --noproxy '*' --basic --user "${KIE_ADMIN_USER}:${KIE_ADMIN_PWD}" ${KIE_SERVER_URL} > ${CURL_OUTPUT} 2>${CURL_ERROR}
CONNECT_RESULT=$?
if [ $CONNECT_RESULT -ne 0 ] ; 
then
    echo "Curl couldn't connect to KIE service! " 
    exit 1;
else
    GREP_SEARCH="error"
    cat ${CURL_OUTPUT} | grep -qi "${GREP_SEARCH}"
    GREP_RESULT=$?
    if [ $GREP_RESULT -eq 0 ] ; then
        echo "Found error in curl output! " 
        cat ${CURL_OUTPUT} | grep -i "${GREP_SEARCH}"
        exit 1;
    fi
fi



if python $JBOSS_HOME/bin/probes/runner.py -c READY --maxruns $COUNT --sleep $SLEEP $DEBUG_OPTIONS $PROBE_IMPL; then
    exit 0
fi
exit 1

