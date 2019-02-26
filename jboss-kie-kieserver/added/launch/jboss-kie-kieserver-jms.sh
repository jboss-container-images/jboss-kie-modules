#!/bin/bash

source "${JBOSS_HOME}/bin/launch/launch-common.sh"
source "${JBOSS_HOME}/bin/launch/logging.sh"


function prepareEnv() {
    # please keep these in alphabetical order
    unset KIE_SERVER_EXECUTOR_JMS
    unset KIE_SERVER_EXECUTOR_JMS_TRANSACTED
    unset KIE_SERVER_JMS_QUEUE_EXECUTOR
    unset KIE_SERVER_JMS_QUEUE_RESPONSE
    unset KIE_SERVER_JMS_QUEUE_REQUEST

}

function preConfigure() {
    KIE_JMS_FILE="${JBOSS_HOME}/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml"
    KIE_EJB_JAR_FILE="${JBOSS_HOME}/standalone/deployments/ROOT.war/WEB-INF/ejb-jar.xml"
}

function configure() {
    configureJmsQueues
    configureJmsExecutor
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
    local queueRequestName=${queueRequest#*/}
    local queueResponse="${KIE_SERVER_JMS_QUEUE_RESPONSE:-queue/KIE.SERVER.RESPONSE}"
    local queueResponseName=${queueResponse#*/}
    sed -i "s,queue/KIE\.SERVER\.REQUEST,${queueRequest},g" ${KIE_JMS_FILE}
    sed -i "s,queue/KIE\.SERVER\.REQUEST,${queueRequest},g" ${KIE_EJB_JAR_FILE}
    sed -i "s,queue/KIE\.SERVER\.RESPONSE,${queueResponse},g" ${KIE_JMS_FILE}
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dkie.server.jms.queues.response=${queueResponse}"
}

function configureJmsExecutor() {
    local queueExecutor="${KIE_SERVER_JMS_QUEUE_EXECUTOR:-queue/KIE.SERVER.EXECUTOR}"
    local queueExecutorName=${queueExecutor#*/}
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