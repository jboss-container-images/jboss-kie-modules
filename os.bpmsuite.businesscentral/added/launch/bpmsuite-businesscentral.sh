#!/bin/bash

source "${JBOSS_HOME}/bin/launch/launch-common.sh"
source "${JBOSS_HOME}/bin/launch/login-modules-common.sh"
source "${JBOSS_HOME}/bin/launch/management-common.sh"
source $JBOSS_HOME/bin/launch/logging.sh

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
    unset KIE_SERVER_CONTROLLER_HOST
    unset KIE_SERVER_CONTROLLER_PORT
    unset KIE_SERVER_CONTROLLER_PROTOCOL
    unset KIE_SERVER_CONTROLLER_PWD
    unset KIE_SERVER_CONTROLLER_SERVICE
    unset KIE_SERVER_CONTROLLER_TOKEN
    unset KIE_SERVER_CONTROLLER_USER
    unset KIE_SERVER_PWD
    unset KIE_SERVER_TOKEN
    unset KIE_SERVER_USER
    unset MAVEN_REPO_PASSWORD
    unset MAVEN_REPO_USERNAME
}

function configureEnv() {
    configure
}

function configure() {
    configure_metaspace
    configure_controller_access
    configure_server_access
    configure_maven_security
    configure_guvnor_settings
    configure_misc_security
    configure_ha
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
    local kieServerControllerUser=$(find_env "KIE_SERVER_CONTROLLER_USER" "controllerUser")
    local kieServerControllerPwd=$(find_env "KIE_SERVER_CONTROLLER_PWD" "controller1!")
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.controller.user=${kieServerControllerUser}"
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.controller.pwd=${kieServerControllerPwd}"
    # token
    if [ "${KIE_SERVER_CONTROLLER_TOKEN}" != "" ]; then
        JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.controller.token=${KIE_SERVER_CONTROLLER_TOKEN}"
    fi
}

function configure_server_access() {
    # user/pwd
    local kieServerUser=$(find_env "KIE_SERVER_USER" "executionUser")
    local kieServerPwd=$(find_env "KIE_SERVER_PWD" "execution1!")
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.user=${kieServerUser}"
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.pwd=${kieServerPwd}"
    # token
    if [ "${KIE_SERVER_TOKEN}" != "" ]; then
        JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.token=${KIE_SERVER_TOKEN}"
    fi
}

function configure_maven_security() {
    local kieServerMavenUser=$(find_env "MAVEN_REPO_USERNAME" "mavenUser")
    local kieServerMavenPwd=$(find_env "MAVEN_REPO_PASSWORD" "maven1!")
    ${JBOSS_HOME}/bin/add-user.sh -a --user "${kieServerMavenUser}" --password "${kieServerMavenPwd}"
    if [ "$?" -ne "0" ]; then
        log_error "Failed to create maven user \"${kieServerMavenUser}\""
        log_error "Exiting..."
        exit
    fi
}

function configure_guvnor_settings() {
    # see scripts/os.bpmsuite.common/configure.sh
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.jbpm.designer.perspective=full -Ddesignerdataobjects=false"
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.demo=false -Dorg.kie.example=false"
    local bpmsuiteDataDir="${JBOSS_HOME}/standalone/data/bpmsuite"
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.guvnor.m2repo.dir=${bpmsuiteDataDir}/maven-repository"
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.uberfire.metadata.index.dir=${bpmsuiteDataDir}"
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.uberfire.nio.git.dir=${bpmsuiteDataDir}"
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.uberfire.nio.git.ssh.cert.dir=${bpmsuiteDataDir}"
}

function configure_misc_security() {
    add_management_interface_realm
    # KieLoginModule breaks Decision Central; it needs to be added only for Business Central & Business Central Monitoring
    # bpmsuite-businesscentral, bpmsuite-businesscentral-monitoring, rhpam-businesscentral, rhpam-businesscentral-monitoring
    if [[ $JBOSS_PRODUCT =~ (bpmsuite|rhpam)\-businesscentral(\-monitoring)? ]]; then
        configure_login_modules "org.kie.security.jaas.KieLoginModule" "optional" "deployment.ROOT.war"
    fi
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
              JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dappformer-jms-url=tcp://${APPFORMER_JMS_BROKER_ADDRESS}:${APPFORMTER_JMS_BROKER_PORT:-61616}"
              JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dappformer-jms-username=${APPFORMER_JMS_BROKER_USER} -Dappformer-jms-password=${APPFORMER_JMS_BROKER_PASSWORD}"
              JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dappformer-cluster=true -Dorg.appformer.ext.metadata.index=elastic -Des.set.netty.runtime.available.processors=false"
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
