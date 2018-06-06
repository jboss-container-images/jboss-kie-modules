#!/bin/bash

source "${JBOSS_HOME}/bin/launch/launch-common.sh"
source "${JBOSS_HOME}/bin/launch/login-modules-common.sh"
source "${JBOSS_HOME}/bin/launch/management-common.sh"
source "${JBOSS_HOME}/bin/launch/logging.sh"
source "${JBOSS_HOME}/bin/launch/bpmsuite-security.sh"

function prepareEnv() {
    # please keep these in alphabetical order
    unset APPFORMER_ELASTIC_CLUSTER_NAME
    unset APPFORMER_ELASTIC_HOST
    unset APPFORMER_ELASTIC_PORT
    unset APPFORMER_ELASTIC_RETRIES
    unset APPFORMER_JMS_BROKER_ADDRESS
    unset APPFORMER_JMS_BROKER_PASSWORD
    unset APPFORMER_JMS_BROKER_PORT
    unset APPFORMER_JMS_BROKER_USER
    unset APPFORMER_JMS_CONNECTION_PARAMS
    unset_kie_security_env
    unset KIE_SERVER_CONTROLLER_HOST
    unset KIE_SERVER_CONTROLLER_PORT
    unset KIE_SERVER_CONTROLLER_PROTOCOL
    unset KIE_SERVER_CONTROLLER_SERVICE
}

function configureEnv() {
    configure
}

function configure() {
    configure_admin_security
    configure_controller_access
    configure_server_access
    configure_guvnor_settings
    configure_metaspace
    configure_ha
}

function configure_admin_security() {
    # add eap users (see bpmsuite-security.sh)
    add_kie_admin_user
    add_kie_server_controller_user
    if [[ $JBOSS_PRODUCT != *monitoring ]]; then
        add_kie_maven_user
    fi

    # (see management-common.sh and login-modules-common.sh)
    add_management_interface_realm
    # KieLoginModule breaks Decision Central; it needs to be added only for Business Central & Business Central Monitoring
    # bpmsuite-businesscentral, bpmsuite-businesscentral-monitoring, rhpam-businesscentral, rhpam-businesscentral-monitoring
    if [[ $JBOSS_PRODUCT =~ (bpmsuite|rhpam)\-businesscentral(\-monitoring)? ]]; then
        configure_login_modules "org.kie.security.jaas.KieLoginModule" "optional" "deployment.ROOT.war"
    fi
}

# here in case the controller is separate from business central
function configure_controller_access {
    # We will only support one controller, whether running by itself or in business central.
    local controllerService="${KIE_SERVER_CONTROLLER_SERVICE}"
    controllerService=${controllerService^^}
    controllerService=${controllerService//-/_}
    # host
    local kieServerControllerHost="${KIE_SERVER_CONTROLLER_HOST}"
    if [ "${kieServerControllerHost}" = "" ]; then
        kieServerControllerHost=$(find_env "${controllerService}_SERVICE_HOST")
    fi
    if [ "${kieServerControllerHost}" != "" ]; then
        # protocol
        local kieServerControllerProtocol=$(find_env "KIE_SERVER_CONTROLLER_PROTOCOL" "http")
        # port
        local kieServerControllerPort="${KIE_SERVER_CONTROLLER_PORT}"
        if [ "${kieServerControllerPort}" = "" ]; then
            kieServerControllerPort=$(find_env "${controllerService}_SERVICE_PORT" "8080")
        fi
        # path
        local kieServerControllerPath="rest/controller"
        if [ "${kieServerControllerProtocol}" = "ws" ]; then
            kieServerControllerPath="websocket/controller"
        fi
        # url
        local kieServerControllerUrl="${kieServerControllerProtocol}://${kieServerControllerHost}:${kieServerControllerPort}/${kieServerControllerPath}"
        JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.controller=${kieServerControllerUrl}"
    fi
    # user/pwd
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.controller.user=\"$(get_kie_server_controller_user)\""
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.controller.pwd=\"$(esc_kie_server_controller_pwd)\""
    # token
    local kieServerControllerToken="$(get_kie_server_controller_token)"
    if [ "${kieServerControllerToken}" != "" ]; then
        JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.controller.token=\"${kieServerControllerToken}\""
    fi
}

function configure_server_access() {
    # user/pwd
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.user=\"$(get_kie_server_user)\""
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.pwd=\"$(esc_kie_server_pwd)\""
    # token
    local kieServerToken="$(get_kie_server_token)"
    if [ "${kieServerToken}" != "" ]; then
        JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.token=\"${kieServerToken}\""
    fi
}

function configure_guvnor_settings() {
    # see scripts/os.bpmsuite.common/configure.sh
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.jbpm.designer.perspective=full -Ddesignerdataobjects=false"
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.demo=false -Dorg.kie.example=false"
    local bpmsuiteDataDir="${JBOSS_HOME}/standalone/data/bpmsuite"
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.guvnor.m2repo.dir=${bpmsuiteDataDir}/maven-repository"
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.uberfire.nio.git.dir=${bpmsuiteDataDir}"
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.uberfire.nio.git.ssh.cert.dir=${bpmsuiteDataDir}"
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.uberfire.nio.git.daemon.enabled=false"
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.uberfire.nio.git.ssh.host=0.0.0.0"
}

# Set the max metaspace size only for the workbench
# It avoid to set the max metaspace size if there is a multiple container instantiation.
function configure_metaspace() {
    export GC_MAX_METASPACE_SIZE=${WORKBENCH_MAX_METASPACE_SIZE:-1024}
}

# required envs for HA
function configure_ha() {
    # for now lets just use DNS_PING, if KUBE ping is also needed we can add it later
    if [ "${JGROUPS_PING_PROTOCOL}" = "openshift.DNS_PING" ]; then
        if [ -n "${OPENSHIFT_DNS_PING_SERVICE_NAME}" -a "${OPENSHIFT_DNS_PING_SERVICE_PORT}" ]; then
            #local artemisAddress=`hostname -i`
            log_info "OpenShift DNS_PING protocol envs set, verifying other needed envs for HA setup. Using ${JGROUPS_PING_PROTOCOL}"
            if [ -n "$APPFORMER_ELASTIC_HOST" -a -n "$APPFORMER_JMS_BROKER_USER" -a -n "$APPFORMER_JMS_BROKER_PASSWORD" -a -n "$APPFORMER_JMS_BROKER_ADDRESS" ] ; then
              local jmsConnectionParams="${APPFORMER_JMS_CONNECTION_PARAMS:-ha=true&retryInterval=1000&retryIntervalMultiplier=1.0&reconnectAttempts=-1}"
              JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dappformer-cluster=true -Dappformer-jms-url=tcp://${APPFORMER_JMS_BROKER_ADDRESS}:${APPFORMTER_JMS_BROKER_PORT:-61616}?${jmsConnectionParams}"
              JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dappformer-jms-username=${APPFORMER_JMS_BROKER_USER} -Dappformer-jms-password=${APPFORMER_JMS_BROKER_PASSWORD}"
              JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dappformer-jms-connection-mode=REMOTE -Dorg.appformer.ext.metadata.index=elastic"
              JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Des.set.netty.runtime.available.processors=false"
              JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.appformer.ext.metadata.elastic.port=${APPFORMER_ELASTIC_PORT:-9300}"
              JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.appformer.ext.metadata.elastic.host=${APPFORMER_ELASTIC_HOST}"
              JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.appformer.ext.metadata.elastic.cluster=${APPFORMER_ELASTIC_CLUSTER_NAME:-kie-cluster}"
              JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.appformer.ext.metadata.elastic.retries=${APPFORMER_ELASTIC_RETRIES:-10}"
            else
              log_warning "HA envs not set, HA will not be configured."
            fi
        else
            log_warning "Missing configuration for JBoss HA. Envs OPENSHIFT_DNS_PING_SERVICE_NAME and OPENSHIFT_DNS_PING_SERVICE_PORT not found."
        fi
    else
        log_warning "JGROUPS_PING_PROTOCOL not set, HA will not be available."
    fi
}
