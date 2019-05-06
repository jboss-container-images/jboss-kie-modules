#!/bin/bash

source "${JBOSS_HOME}/bin/launch/launch-common.sh"
source "${JBOSS_HOME}/bin/launch/login-modules-common.sh"
source "${JBOSS_HOME}/bin/launch/jboss-kie-wildfly-common.sh"
source "${JBOSS_HOME}/bin/launch/management-common.sh"
source "${JBOSS_HOME}/bin/launch/logging.sh"
source "${JBOSS_HOME}/bin/launch/jboss-kie-wildfly-security.sh"

function prepareEnv() {
    # please keep these in alphabetical order
    unset APPFORMER_ELASTIC_CLUSTER_NAME
    unset APPFORMER_ELASTIC_HOST
    unset APPFORMER_ELASTIC_PORT
    unset APPFORMER_ELASTIC_RETRIES
    unset APPFORMER_ELASTIC_SERVICE_NAME
    unset APPFORMER_INFINISPAN_HOST
    unset APPFORMER_INFINISPAN_PASSWORD
    unset APPFORMER_INFINISPAN_PORT
    unset APPFORMER_INFINISPAN_REALM
    unset APPFORMER_INFINISPAN_SASL_QOP
    unset APPFORMER_INFINISPAN_SERVER_NAME
    unset APPFORMER_INFINISPAN_SERVICE_NAME
    unset APPFORMER_INFINISPAN_USER
    unset APPFORMER_INFINISPAN_USERNAME
    unset APPFORMER_JMS_BROKER_ADDRESS
    unset APPFORMER_JMS_BROKER_PASSWORD
    unset APPFORMER_JMS_BROKER_PORT
    unset APPFORMER_JMS_BROKER_USER
    unset APPFORMER_JMS_BROKER_USERNAME
    unset APPFORMER_JMS_CONNECTION_PARAMS
    unset BUILD_ENABLE_INCREMENTAL
    unset GIT_HOOKS_DIR
    unset_kie_security_env
    unset KIE_SERVER_CONTROLLER_HOST
    unset KIE_SERVER_CONTROLLER_OPENSHIFT_GLOBAL_DISCOVERY_ENABLED
    unset KIE_SERVER_CONTROLLER_OPENSHIFT_PREFER_KIESERVER_SERVICE
    unset KIE_SERVER_CONTROLLER_PORT
    unset KIE_SERVER_CONTROLLER_PROTOCOL
    unset KIE_SERVER_CONTROLLER_SERVICE
    unset KIE_SERVER_CONTROLLER_TEMPLATE_CACHE_TTL
    unset KIE_WORKBENCH_CONTROLLER_OPENSHIFT_ENABLED
}

function configureEnv() {
    configure
}

function configure() {
    configure_admin_security
    configure_controller_access
    configure_server_access
    configure_openshift_enhancement
    configure_workbench_profile
    configure_guvnor_settings
    configure_metaspace
    configure_ha
}

function configure_admin_security() {
    # add eap users (see jboss-kie-wildfly-security.sh)
    add_kie_admin_user
    add_kie_server_controller_user
    if [[ $JBOSS_PRODUCT != *monitoring ]]; then
        add_kie_maven_user
    fi
    print_user_information "central"

    # (see management-common.sh and login-modules-common.sh)
    add_management_interface_realm
    # KieLoginModule breaks Decision Central; it needs to be added only for Business Central & Business Central Monitoring
    # rhpam-businesscentral, rhpam-businesscentral-monitoring
    if [[ $JBOSS_PRODUCT =~ rhpam\-businesscentral(\-monitoring)? ]]; then
        configure_login_modules "org.kie.security.jaas.KieLoginModule" "optional" "deployment.ROOT.war"
    fi
}

# here in case the controller is separate from business central
function configure_controller_access {
    # We will only support one controller, whether running by itself or in business central.
    local kieServerControllerService="${KIE_SERVER_CONTROLLER_SERVICE}"
    kieServerControllerService=${kieServerControllerService^^}
    kieServerControllerService=${kieServerControllerService//-/_}
    # host
    local kieServerControllerHost="${KIE_SERVER_CONTROLLER_HOST}"
    if [ "${kieServerControllerHost}" = "" ]; then
        kieServerControllerHost=$(find_env "${kieServerControllerService}_SERVICE_HOST")
    fi
    if [ "${kieServerControllerHost}" != "" ]; then
        # protocol
        local kieSererControllerProtocol=$(find_env "KIE_SERVER_CONTROLLER_PROTOCOL" "http")
        # port
        local kieServerControllerPort="${KIE_SERVER_CONTROLLER_PORT}"
        if [ "${kieServerControllerPort}" = "" ]; then
            kieServerControllerPort=$(find_env "${kieServerControllerService}_SERVICE_PORT" "8080")
        fi
        # path
        local kieServerControllerPath="/rest/controller"
        if [ "${kieSererControllerProtocol}" = "ws" ]; then
            kieServerControllerPath="/websocket/controller"
        fi
        # url
        local kieServerControllerUrl=$(build_simple_url "${kieSererControllerProtocol}" "${kieServerControllerHost}" "${kieServerControllerPort}" "${kieServerControllerPath}")
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.controller=${kieServerControllerUrl}"
    fi
    # user/pwd
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.controller.user=\"$(get_kie_server_controller_user)\""
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.controller.pwd=\"$(esc_kie_server_controller_pwd)\""
    # token
    local kieServerControllerToken="$(get_kie_server_controller_token)"
    if [ "${kieServerControllerToken}" != "" ]; then
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.controller.token=\"${kieServerControllerToken}\""
    fi
}

function configure_server_access() {
    # user/pwd
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.user=\"$(get_kie_server_user)\""
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.pwd=\"$(esc_kie_server_pwd)\""
    # token
    local kieServerToken="$(get_kie_server_token)"
    if [ "${kieServerToken}" != "" ]; then
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.token=\"${kieServerToken}\""
    fi
}

function configure_openshift_enhancement() {
    local kscGlobalDiscoveryEnabled=$(find_env "KIE_SERVER_CONTROLLER_OPENSHIFT_GLOBAL_DISCOVERY_ENABLED" "false")
    local kscPreferKieService=$(find_env "KIE_SERVER_CONTROLLER_OPENSHIFT_PREFER_KIESERVER_SERVICE" "false")
    local kscTemplateCacheTTL=$(find_env "KIE_SERVER_CONTROLLER_TEMPLATE_CACHE_TTL" "60000")
    local kscOpenShiftEnabled=$(find_env "KIE_WORKBENCH_CONTROLLER_OPENSHIFT_ENABLED" "false")

    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.controller.openshift.global.discovery.enabled=${kscGlobalDiscoveryEnabled}"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.controller.openshift.prefer.kieserver.service=${kscPreferKieService}"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.controller.template.cache.ttl=${kscTemplateCacheTTL}"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.workbench.controller.openshift.enabled=${kscOpenShiftEnabled}"
}

function configure_workbench_profile() {
    # Business Central is unified for RHDM and RHPAM; For rhpam-decisioncentral needs to be set org.kie.workbench.profile
    # to FORCE_PLANNER_AND_RULES and for rhpam-businesscentral and rhpam-businesscentral-monitoring needst to be set to
    # FORCE_FULL
    if [ "$JBOSS_PRODUCT" = "rhdm-decisioncentral" ]; then
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.workbench.profile=FORCE_PLANNER_AND_RULES"
    elif [[ $JBOSS_PRODUCT =~ rhpam\-businesscentral(\-monitoring)? ]]; then
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.workbench.profile=FORCE_FULL"
    fi
}

function configure_guvnor_settings() {
    local buildEnableIncremental="${BUILD_ENABLE_INCREMENTAL,,}"
    # only set the system property if we have a valid value, as it is an override and we should not default
    if [ "${buildEnableIncremental}" = "true" ] || [ "${buildEnableIncremental}" = "false" ]; then
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dbuild.enable-incremental=${buildEnableIncremental}"
    fi
    # see scripts/jboss-kie-wildfly-common/configure.sh
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.jbpm.designer.perspective=full -Ddesignerdataobjects=false"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.demo=false -Dorg.kie.example=false"
    local kieDataDir="${JBOSS_HOME}/standalone/data/kie"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.guvnor.m2repo.dir=${kieDataDir}/maven-repository"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.uberfire.nio.git.dir=${kieDataDir}"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.uberfire.nio.git.ssh.cert.dir=${kieDataDir}"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.uberfire.nio.git.daemon.enabled=false"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.uberfire.nio.git.ssh.host=0.0.0.0"
    if [[ $JBOSS_PRODUCT != *monitoring && "${GIT_HOOKS_DIR}" != "" ]]; then
        if [ ! -e "${GIT_HOOKS_DIR}" ]; then
            echo "GIT_HOOKS_DIR directory \"${GIT_HOOKS_DIR}\" does not exist; creating..."
            if mkdir -p "${GIT_HOOKS_DIR}" ; then
                echo "GIT_HOOKS_DIR directory \"${GIT_HOOKS_DIR}\" created."
            else
                echo "GIT_HOOKS_DIR directory \"${GIT_HOOKS_DIR}\" could not be created!"
            fi
        elif  [ -f "${GIT_HOOKS_DIR}" ]; then
            echo "GIT_HOOKS_DIR \"${GIT_HOOKS_DIR}\" cannot be used because it is a file!"
        fi
        if [ -d "${GIT_HOOKS_DIR}" ]; then
            JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.uberfire.nio.git.hooks=${GIT_HOOKS_DIR}"
        fi
    fi
    # maven url
    local maven_url=$(build_route_url "${WORKBENCH_ROUTE_NAME}" "http" "${HOSTNAME}" "80" "/maven2")
    log_info "Setting workbench org.appformer.m2repo.url to: ${maven_url}"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.appformer.m2repo.url=${maven_url}"
    # workbench host
    local workbench_host=$(query_route_host "${WORKBENCH_ROUTE_NAME}" "${HOSTNAME}")
    workbench_host=$(query_route_service_host "${WORKBENCH_ROUTE_NAME}" "${workbench_host}")
    log_info "Setting workbench org.uberfire.nio.git.ssh.hostname to: ${workbench_host}"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.uberfire.nio.git.ssh.hostname=${workbench_host}"
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
        if [ -n "${OPENSHIFT_DNS_PING_SERVICE_NAME}" -a -n "${OPENSHIFT_DNS_PING_SERVICE_PORT}" ]; then
            log_info "OpenShift DNS_PING protocol envs set, verifying other needed envs for HA setup. Using ${JGROUPS_PING_PROTOCOL}"
            local jmsBrokerUsername="${APPFORMER_JMS_BROKER_USERNAME:-$APPFORMER_JMS_BROKER_USER}"
            if [ -n "$jmsBrokerUsername" -a -n "$APPFORMER_JMS_BROKER_PASSWORD" -a -n "$APPFORMER_JMS_BROKER_ADDRESS" ] ; then
                if [ -n "$APPFORMER_INFINISPAN_SERVICE_NAME" -o -n "$APPFORMER_INFINISPAN_HOST" ] ; then
                    # set the workbench properties for HA using Infinispan
                    configure_ha_common
                    configure_ha_infinispan
                elif [ -n "$APPFORMER_ELASTIC_SERVICE_NAME" -o -n "$APPFORMER_ELASTIC_HOST" ] ; then
                    # set the workbench properties for HA using Elasticsearch
                    configure_ha_common
                    configure_ha_elastic
                else
                    log_warning "APPFORMER_INFINISPAN_SERVICE_NAME or APPFORMER_INFINISPAN_HOST, or APPFORMER_ELASTIC_SERVICE_NAME or APPFORMER_ELASTIC_HOST not set; HA will not be available."
                fi
            else
                log_warning "APPFORMER_JMS_BROKER_USER(NAME), APPFORMER_JMS_BROKER_PASSWORD, and APPFORMER_JMS_BROKER_ADDRESS not set; HA will not be available."
            fi
        else
            log_warning "OPENSHIFT_DNS_PING_SERVICE_NAME and OPENSHIFT_DNS_PING_SERVICE_PORT not set; HA will not be available."
        fi
    else
        log_warning "JGROUPS_PING_PROTOCOL not set; HA will not be available."
    fi
}

function configure_ha_common() {
    # ---------- enable ----------
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dappformer-cluster=true"

    # ---------- jms ----------
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dappformer-jms-connection-mode=REMOTE"
    local jmsConnectionParams="${APPFORMER_JMS_CONNECTION_PARAMS:-ha=true&retryInterval=1000&retryIntervalMultiplier=1.0&reconnectAttempts=-1}"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dappformer-jms-url=tcp://${APPFORMER_JMS_BROKER_ADDRESS}:${APPFORMTER_JMS_BROKER_PORT:-61616}?${jmsConnectionParams}"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dappformer-jms-username=${APPFORMER_JMS_BROKER_USERNAME:-$APPFORMER_JMS_BROKER_USER}"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dappformer-jms-password=${APPFORMER_JMS_BROKER_PASSWORD}"

    # ---------- distributable ----------
    # [RHPAM-1522] make the workbench webapp distributable for HA (2 steps)
    # step 1) uncomment the <distributable/> tag
    local web_xml="${JBOSS_HOME}/standalone/deployments/ROOT.war/WEB-INF/web.xml"
    sed -i "/^\s*<!--/!b;N;/<distributable\/>/s/.*\n//;T;:a;n;/^\s*-->/!ba;d" "${web_xml}"
    # step 2) modify the web cache container per https://access.redhat.com/solutions/2776221
    #         note: the below differs from the EAP 7.1 solution above, since EAP 7.2
    #               doesn't have "mode", "l1", and "owners" attributes in the original config
    local web_cache="\
        <transport lock-timeout='60000'/>\
        <replicated-cache name='repl'>\
            <file-store/>\
        </replicated-cache>\
        <distributed-cache name='dist'>\
            <file-store/>\
        </distributed-cache>"
    xmllint --shell "${JBOSS_HOME}/standalone/configuration/standalone-openshift.xml" << SHELL
        cd //*[local-name()='cache-container'][@name='web']
        set ${web_cache}
        save
SHELL
# SHELL line above not indented on purpose for correct vim syntax highlighting
}

function configure_ha_infinispan() {
    local serviceName
    if [ -n "${APPFORMER_INFINISPAN_SERVICE_NAME}" ]; then
        serviceName=${APPFORMER_INFINISPAN_SERVICE_NAME//-/_} # replace - with _
        serviceName=${serviceName^^} # uppercase
    fi
    if [ -z "${APPFORMER_INFINISPAN_HOST}" ] && [ -n "${serviceName}" ]; then
        APPFORMER_INFINISPAN_HOST=$(find_env "${serviceName}_SERVICE_HOST")
    fi
    if [ -z "${APPFORMER_INFINISPAN_PORT}" ] && [ -n "${serviceName}" ]; then
        APPFORMER_INFINISPAN_PORT=$(find_env "${serviceName}_SERVICE_PORT")
    fi
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.appformer.ext.metadata.index=infinispan"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.appformer.ext.metadata.infinispan.host=${APPFORMER_INFINISPAN_HOST}"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.appformer.ext.metadata.infinispan.port=${APPFORMER_INFINISPAN_PORT:-11222}"
    if [ -n "${APPFORMER_INFINISPAN_USERNAME}" -o -n "${APPFORMER_INFINISPAN_USER}" ] ; then
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.appformer.ext.metadata.infinispan.username=${APPFORMER_INFINISPAN_USERNAME:-$APPFORMER_INFINISPAN_USER}"
    fi
    if [ -n "${APPFORMER_INFINISPAN_PASSWORD}" ] ; then
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.appformer.ext.metadata.infinispan.password=${APPFORMER_INFINISPAN_PASSWORD}"
    fi
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.appformer.ext.metadata.infinispan.realm=${APPFORMER_INFINISPAN_REALM:-ApplicationRealm}"
    if [ -n "${APPFORMER_INFINISPAN_SERVER_NAME}" ] ; then
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.appformer.ext.metadata.infinispan.server.name=${APPFORMER_INFINISPAN_SERVER_NAME}"
    fi
    if [ -n "${APPFORMER_INFINISPAN_SASL_QOP}" ] ; then
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.appformer.ext.metadata.infinispan.sasl.qop=${APPFORMER_INFINISPAN_SASL_QOP}"
    fi
}

function configure_ha_elastic() {
    local serviceName
    if [ -n "${APPFORMER_ELASTIC_SERVICE_NAME}" ]; then
        serviceName=${APPFORMER_ELASTIC_SERVICE_NAME//-/_} # replace - with _
        serviceName=${serviceName^^} # uppercase
    fi
    if [ -z "${APPFORMER_ELASTIC_HOST}" ] && [ -n "${serviceName}" ]; then
        APPFORMER_ELASTIC_HOST=$(find_env "${serviceName}_SERVICE_HOST")
    fi
    if [ -z "${APPFORMER_ELASTIC_PORT}" ] && [ -n "${serviceName}" ]; then
        APPFORMER_ELASTIC_PORT=$(find_env "${serviceName}_SERVICE_PORT")
    fi
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Des.set.netty.runtime.available.processors=false"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.appformer.ext.metadata.index=elastic"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.appformer.ext.metadata.elastic.cluster=${APPFORMER_ELASTIC_CLUSTER_NAME:-kie-cluster}"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.appformer.ext.metadata.elastic.host=${APPFORMER_ELASTIC_HOST}"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.appformer.ext.metadata.elastic.port=${APPFORMER_ELASTIC_PORT:-9300}"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.appformer.ext.metadata.elastic.retries=${APPFORMER_ELASTIC_RETRIES:-10}"
}
