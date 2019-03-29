#!/bin/bash

source "${JBOSS_HOME}/bin/launch/launch-common.sh"
source "${JBOSS_HOME}/bin/launch/logging.sh"


function prepareEnv() {
    # please keep these in alphabetical order
    unset KIE_SERVER_EXECUTOR_JMS
    unset KIE_SERVER_EXECUTOR_JMS_TRANSACTED
    unset KIE_SERVER_JMS_ENABLE_SIGNAL
    unset KIE_SERVER_JMS_QUEUE_EXECUTOR
    unset KIE_SERVER_JMS_QUEUE_RESPONSE
    unset KIE_SERVER_JMS_QUEUE_REQUEST
    unset KIE_SERVER_JMS_QUEUE_SIGNAL
}

function preConfigure() {
    KIE_JMS_FILE="${JBOSS_HOME}/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml"
    KIE_EJB_JAR_FILE="${JBOSS_HOME}/standalone/deployments/ROOT.war/WEB-INF/ejb-jar.xml"
}

function configure() {
    configureJmsQueues
    configureJmsExecutor
    configureJmsSignal
}

function postConfigure {
    # If resource adapter is going to be used, remove the kie-server-jms.xml file to avoid duplicated resources
    # In order to configure RA the env MQ_SERVICE_PREFIX_MAPPING must be defined, we'll look for it, if present,
    # remove it.
    if [ "${MQ_SERVICE_PREFIX_MAPPING}x" != "x"  ]; then
        log_info "Configuring external JMS integration, removing ${KIE_JMS_FILE}"
        rm -rfv ${KIE_JMS_FILE}
    fi
}

configureJmsQueues() {
    local queueRequest="${KIE_SERVER_JMS_QUEUE_REQUEST:-queue/KIE.SERVER.REQUEST}"
    local queueResponse="${KIE_SERVER_JMS_QUEUE_RESPONSE:-queue/KIE.SERVER.RESPONSE}"
    sed -i "s,queue/KIE\.SERVER\.REQUEST,${queueRequest},g" ${KIE_JMS_FILE}
    sed -i "s,queue/KIE\.SERVER\.REQUEST,${queueRequest},g" ${KIE_EJB_JAR_FILE}
    sed -i "s,queue/KIE\.SERVER\.RESPONSE,${queueResponse},g" ${KIE_JMS_FILE}
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dkie.server.jms.queues.response=${queueResponse}"
}

function configureJmsExecutor() {
    local queueExecutor="${KIE_SERVER_JMS_QUEUE_EXECUTOR:-queue/KIE.SERVER.EXECUTOR}"
    sed -i "s,queue/KIE\.SERVER\.EXECUTOR,${queueExecutor},g" ${KIE_JMS_FILE}
    sed -i "s,queue/KIE\.SERVER\.EXECUTOR,${queueExecutor},g" ${KIE_EJB_JAR_FILE}

    # JMS is the default executor
    local enableJmsExecutor=${KIE_SERVER_EXECUTOR_JMS:-true}
    # default transacted to faulse
    if [ "${KIE_SERVER_EXECUTOR_JMS_TRANSACTED^^}" = "TRUE" ]; then
        KIE_SERVER_EXECUTOR_JMS_TRANSACTED="true"
    else
        KIE_SERVER_EXECUTOR_JMS_TRANSACTED="false"
    fi
    if [ "${enableJmsExecutor^^}" = "TRUE" -a "${JBOSS_PRODUCT}" = "rhpam-kieserver" ]; then
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.executor.jms=${enableJmsExecutor}"
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.executor.jms.queue=${queueExecutor}"
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.executor.jms.transacted=${KIE_SERVER_EXECUTOR_JMS_TRANSACTED}"
    else
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.executor.jms=false"
    fi

}

function configureJmsSignal() {
    if [ "${KIE_SERVER_JMS_ENABLE_SIGNAL^^}" = "TRUE" ]; then
        log_info "Configuring Signal messaging queue"
        first=$(grep -B1 -n ' <jms-queue name="KIE.SERVER.SIGNAL.QUEUE">' ${KIE_JMS_FILE} | head -n 1 | cut -d- -f1)
        last=$(grep -10 -n ' <jms-queue name="KIE.SERVER.SIGNAL.QUEUE">' ${KIE_JMS_FILE} | grep -e '-[[:space:]]*-->' | cut -d- -f1)
        sed -i "${first}d; ${last}d" ${KIE_JMS_FILE}
        sed -i 's/<!--##JMS_SIGNAL//; s/JMS_SIGNAL##-->//' ${KIE_EJB_JAR_FILE}
        local queueSignal="${KIE_SERVER_JMS_QUEUE_SIGNAL:-queue/KIE.SERVER.SIGNAL}"
        sed -i "s,queue/KIE\.SERVER\.SIGNAL,${queueSignal},g" ${KIE_JMS_FILE}
        sed -i "s,queue/KIE\.SERVER\.SIGNAL,${queueSignal},g" ${KIE_EJB_JAR_FILE}
    fi
}
