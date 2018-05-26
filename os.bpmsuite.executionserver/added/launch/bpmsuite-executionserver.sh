#!/bin/bash

source "${JBOSS_HOME}/bin/launch/launch-common.sh"
source "${JBOSS_HOME}/bin/launch/logging.sh"
source "${JBOSS_HOME}/bin/launch/bpmsuite-security.sh"

function prepareEnv() {
    # please keep these in alphabetical order
    unset AUTO_CONFIGURE_EJB_TIMER
    unset DROOLS_SERVER_FILTER_CLASSES
    unset JBPM_HT_CALLBACK_CLASS
    unset JBPM_HT_CALLBACK_METHOD
    unset JBPM_LOOP_LEVEL_DISABLED
    unset KIE_EXECUTOR_RETRIES
    unset_kie_security_env
    unset KIE_SERVER_CONTAINER_DEPLOYMENT
    unset KIE_SERVER_CONTROLLER_HOST
    unset KIE_SERVER_CONTROLLER_PORT
    unset KIE_SERVER_CONTROLLER_PROTOCOL
    unset KIE_SERVER_CONTROLLER_SERVICE
    unset KIE_SERVER_HOST
    unset KIE_SERVER_ID
    unset KIE_SERVER_MGMT_DISABLED
    unset KIE_SERVER_PERSISTENCE_DIALECT
    unset KIE_SERVER_PERSISTENCE_DS
    unset KIE_SERVER_PERSISTENCE_SCHEMA
    unset KIE_SERVER_PERSISTENCE_TM
    unset KIE_SERVER_PORT
    unset KIE_SERVER_PROTOCOL
    unset KIE_SERVER_ROUTER_HOST
    unset KIE_SERVER_ROUTER_PORT
    unset KIE_SERVER_ROUTER_PROTOCOL
    unset KIE_SERVER_ROUTER_SERVICE
    unset KIE_SERVER_STARTUP_STRATEGY
    unset KIE_SERVER_SYNC_DEPLOY
}

function preConfigure() {
    configure_EJB_Timer_datasource
}

function configureEnv() {
    configure
}

function configure() {
    # configure_server_env always has to be first
    configure_server_env
    configure_controller_access
    configure_router_access
    configure_server_location
    configure_server_persistence
    configure_server_security
    configure_server_sync_deploy
    configure_drools
    configure_executor
    configure_jbpm
    configure_kie_server_mgmt
    # configure_server_state always has to be last
    configure_server_state
}

function configure_EJB_Timer_datasource {

    source $JBOSS_HOME/bin/launch/datasource-common.sh

    local autoConfigure=${AUTO_CONFIGURE_EJB_TIMER:-true}
    if [ "${autoConfigure^^}" = "TRUE" ]; then
        log_info "EJB Timer will be auto configured if any datasource is configured via DB_SERVICE_PREFIX_MAPPING or DATASOURCES envs."

        # configure the EJB timer datasource based on DB_SERVICE_PREFIX_MAPPING
        if [ -n "${DB_SERVICE_PREFIX_MAPPING}" ]; then
            log_info "configuring EJB Timer Datasource based on DB_SERVICE_PREFIX_MAPPING env"
            local serviceMappingName=${DB_SERVICE_PREFIX_MAPPING%=*}
            local prefix=${DB_SERVICE_PREFIX_MAPPING#*=}

            EJB_TIMER_JNDI=$(find_env "${prefix}_JNDI")
            EJB_TIMER_JNDI="${EJB_TIMER_JNDI}_EJBTimer"

            # force the provided datasource to be xa
            eval ${prefix}_NONXA=false

            #mysql need to be created manually because the DB_SERVICE_PREFIX_MAPPING does not allow to configure the XA URL
            if [[ "${serviceMappingName}" = *"mysql"* ]]; then
                DATASOURCES="EJB_TIMER"

                local service=${serviceMappingName^^}
                service=${service//-/_}
                local host=$(find_env "${service}_SERVICE_HOST")
                local port=$(find_env "${service}_SERVICE_PORT" "3306")
                local database=$(find_env "${prefix}_DATABASE")
                EJB_TIMER_DRIVER="mysql"
                EJB_TIMER_XA_CONNECTION_PROPERTY_URL="jdbc:mysql://${host}:${port}/${database}?pinGlobalTxToPhysicalConnection=true"
                EJB_TIMER_CONNECTION_CHECKER=$(find_env "${prefix}_CONNECTION_CHECKER" "org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLValidConnectionChecker")
                EJB_TIMER_EXCEPTION_SORTER=$(find_env "${prefix}_EXCEPTION_SORTER" "org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLExceptionSorter")
                EJB_TIMER_BACKGROUND_VALIDATION=$(find_env "${prefix}_BACKGROUND_VALIDATION" "true")
                EJB_TIMER_BACKGROUND_VALIDATION_MILLIS=$(find_env "${prefix}_BACKGROUND_VALIDATION_MILLIS" "10000")
                TIMER_SERVICE_DATA_STORE="EJB_TIMER"
            else
                # Make sure that the EJB datasource is configured first, in this way the timer's default-data-store wil be the
                # EJBTimer datasource
                DB_SERVICE_PREFIX_MAPPING="${serviceMappingName}=EJB_TIMER,${DB_SERVICE_PREFIX_MAPPING}"
                EJB_TIMER_DATABASE=$(find_env "${prefix}_DATABASE")
                EJB_TIMER_DRIVER="postgresql"
                TIMER_SERVICE_DATA_STORE="${serviceMappingName}"
            fi
            EJB_TIMER_USERNAME=$(find_env "${prefix}_USERNAME")
            EJB_TIMER_PASSWORD=$(find_env "${prefix}_PASSWORD")
            EJB_TIMER_MIN_POOL_SIZE=$(find_env "${prefix}_MIN_POOL_SIZE")
            EJB_TIMER_MAX_POOL_SIZE=$(find_env "${prefix}_MAX_POOL_SIZE")
            EJB_TIMER_TX_ISOLATION="${EJB_TIMER_TX_ISOLATION:-TRANSACTION_READ_COMMITTED}"
            EJB_TIMER_NONXA="false"
            #inject_ejb_timer_datastore

        elif [ -n "${DATASOURCES}" ]; then
            log_info "configuring EJB Timer Datasource based on DATASOURCES env"
            # Make sure that the EJB datasource is configured first, in this way the timer's default-data-store wil be the
            # EJBTimer datasource
            local dsPrefix="${DATASOURCES%,*}"
            # force the provided datasource to be xa
            eval ${dsPrefix}_NONXA=false

            DATASOURCES="EJB_TIMER,${DATASOURCES}"

            EJB_TIMER_DRIVER=$(find_env "${dsPrefix}_DRIVER")

            if [ "${EJB_TIMER_DRIVER}" = "postgresql" ]; then
                EJB_TIMER_DATABASE=$(find_env "${dsPrefix}_DATABASE")
                EJB_TIMER_SERVICE_HOST=$(find_env "${dsPrefix}_SERVICE_HOST")
                EJB_TIMER_SERVICE_PORT=$(find_env "${dsPrefix}_SERVICE_PORT")

            elif [ "${EJB_TIMER_DRIVER}" = "mysql" ]; then
                local host=$(find_env "${dsPrefix}_SERVICE_HOST")
                local port=$(find_env "${dsPrefix}_SERVICE_PORT" "3306")
                local database=$(find_env "${dsPrefix}_DATABASE")
                EJB_TIMER_XA_CONNECTION_PROPERTY_URL="jdbc:mysql://${host}:${port}/${database}?pinGlobalTxToPhysicalConnection=true"
            else
                # these values are set automatically it the driver is mysql or postgresql, if the driver does not match, these values must be provided
                EJB_TIMER_CONNECTION_CHECKER=$(find_env "${dsPrefix}_CONNECTION_CHECKER")
                EJB_TIMER_EXCEPTION_SORTER=$(find_env "${dsPrefix}_EXCEPTION_SORTER")
                EJB_TIMER_BACKGROUND_VALIDATION=$(find_env "${dsPrefix}_BACKGROUND_VALIDATION")
                EJB_TIMER_BACKGROUND_VALIDATION_MILLIS=$(find_env "${dsPrefix}_BACKGROUND_VALIDATION_MILLIS")

                # if prefix_URL and prefix_XA_CONNECTION_PROPERTY_propertyName are set, rely on XA property
                # the same will be valid for others XA properties
                local url=$(find_env "${dsPrefix}_URL")
                url=$(find_env "${dsPrefix}_XA_CONNECTION_PROPERTY_URL" "${url}")
                if [ "x${url}" != "x" ]; then
                    EJB_TIMER_XA_CONNECTION_PROPERTY_URL=${url}

                else
                    local databaseName=$(find_env "${dsPrefix}_DATABASE")
                    databaseName=$(find_env "${dsPrefix}_XA_CONNECTION_PROPERTY_DatabaseName" "${databaseName}")
                    local serverName=$(find_env "${dsPrefix}_SERVICE_HOST" )
                    serverName=$(find_env "${dsPrefix}_XA_CONNECTION_PROPERTY_ServerName" "${serverName}")
                    local portNumber=$(find_env "${dsPrefix}_SERVICE_PORT" )
                    portNumber=$(find_env "${dsPrefix}_XA_CONNECTION_PROPERTY_PortNumber" "${portNumber}")
                    EJB_TIMER_XA_CONNECTION_PROPERTY_DatabaseName=${databaseName}
                    EJB_TIMER_XA_CONNECTION_PROPERTY_ServerName=${serverName}
                    EJB_TIMER_XA_CONNECTION_PROPERTY_PortNumber=${portNumber}
                fi
            fi
            EJB_TIMER_USERNAME=$(find_env "${dsPrefix}_USERNAME")
            EJB_TIMER_PASSWORD=$(find_env "${dsPrefix}_PASSWORD")
            EJB_TIMER_MIN_POOL_SIZE=$(find_env "${dsPrefix}_MIN_POOL_SIZE" "10")
            EJB_TIMER_MAX_POOL_SIZE=$(find_env "${dsPrefix}_MAX_POOL_SIZE" "10")
            EJB_TIMER_NONXA="false"
            EJB_TIMER_TX_ISOLATION="${EJB_TIMER_TX_ISOLATION:-TRANSACTION_READ_COMMITTED}"
            TIMER_SERVICE_DATA_STORE="EJB_TIMER"
        fi
    fi
}

function configure_server_env {
    # source the KIE config
    source $JBOSS_HOME/bin/launch/kieserver-env.sh
    # set the KIE environment
    setKieEnv
    # dump the KIE environment
    dumpKieEnv | tee ${JBOSS_HOME}/kieEnv
    # save the environment for use by the probes
    sed -ri "s/^([^:]+): *(.*)$/\1=\"\2\"/" ${JBOSS_HOME}/kieEnv
}

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
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.controller.user=$(get_kie_server_controller_user)"
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.controller.pwd=$(get_kie_server_controller_pwd)"
    # token
    local kieServerControllerToken="$(get_kie_server_controller_token)"
    if [ "${kieServerControllerToken}" != "" ]; then
        JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.controller.token=${kieServerConrollerToken}"
    fi
}

function configure_router_access {
    local routerService="${KIE_SERVER_ROUTER_SERVICE}"
    routerService=${routerService^^}
    routerService=${routerService//-/_}
    # host
    local kieServerRouterHost="${KIE_SERVER_ROUTER_HOST}"
    if [ "${kieServerRouterHost}" = "" ]; then
        kieServerRouterHost=$(find_env "${routerService}_SERVICE_HOST")
    fi
    if [ "${kieServerRouterHost}" != "" ]; then
        # protocol
        local kieServerRouterProtocol=$(find_env "KIE_SERVER_ROUTER_PROTOCOL" "http")
        # port
        local kieServerRouterPort="${KIE_SERVER_ROUTER_PORT}"
        if [ "${kieServerRouterPort}" = "" ]; then
            kieServerRouterPort=$(find_env "${routerService}_SERVICE_PORT" "9000")
        fi
        # url
        local kieServerRouterUrl="${kieServerRouterProtocol}://${kieServerRouterHost}:${kieServerRouterPort}"
        JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.router=${kieServerRouterUrl}"
    fi
}

function configure_drools() {
    # should the server filter classes?
    if [ "x${DROOLS_SERVER_FILTER_CLASSES}" != "x" ]; then
        # if specified, respect value
        local droolsServerFilterClasses=$(echo "${DROOLS_SERVER_FILTER_CLASSES}" | tr "[:upper:]" "[:lower:]")
        if [ "${droolsServerFilterClasses}" = "true" ]; then
            DROOLS_SERVER_FILTER_CLASSES="true"
        else
            DROOLS_SERVER_FILTER_CLASSES="false"
        fi
    else
        # otherwise, filter classes by default
        DROOLS_SERVER_FILTER_CLASSES="true"
    fi
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.drools.server.filter.classes=${DROOLS_SERVER_FILTER_CLASSES}"
}

function configure_server_location() {
    # DeploymentConfig: spec/template/spec/containers/env
    # {
    #     "name": "KIE_SERVER_HOST",
    #     "valueFrom": {
    #         "fieldRef": {
    #             "fieldPath": "status.podIP"
    #         }
    #     }
    # },
    if [ "${KIE_SERVER_HOST}" = "" ]; then
        KIE_SERVER_HOST="${HOSTNAME}"
    fi
    if [ "${KIE_SERVER_HOST}" != "" ]; then
        if [ "${KIE_SERVER_PROTOCOL}" = "" ]; then
            KIE_SERVER_PROTOCOL="http"
        fi
        if [ "${KIE_SERVER_PORT}" = "" ]; then
            KIE_SERVER_PORT="8080"
        fi
        local kieServerUrl="${KIE_SERVER_PROTOCOL}://${KIE_SERVER_HOST}:${KIE_SERVER_PORT}/services/rest/server"
        JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.location=${kieServerUrl}"
    fi
}

function configure_server_persistence() {
    # dialect
    if [ "${KIE_SERVER_PERSISTENCE_DIALECT}" = "" ]; then
        KIE_SERVER_PERSISTENCE_DIALECT="org.hibernate.dialect.H2Dialect"
    fi
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.persistence.dialect=${KIE_SERVER_PERSISTENCE_DIALECT}"
    # datasource
    if [ "${KIE_SERVER_PERSISTENCE_DS}" = "" ]; then
        if [ "x${DB_JNDI}" != "x" ]; then
            KIE_SERVER_PERSISTENCE_DS="${DB_JNDI}"
        else
            KIE_SERVER_PERSISTENCE_DS="java:/jboss/datasources/ExampleDS"
        fi
    fi
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.persistence.ds=${KIE_SERVER_PERSISTENCE_DS}"
    # transactions
    if [ "${KIE_SERVER_PERSISTENCE_TM}" = "" ]; then
        #KIE_SERVER_PERSISTENCE_TM="org.hibernate.service.jta.platform.internal.JBossAppServerJtaPlatform"
        KIE_SERVER_PERSISTENCE_TM="org.hibernate.engine.transaction.jta.platform.internal.JBossAppServerJtaPlatform"
    fi
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.persistence.tm=${KIE_SERVER_PERSISTENCE_TM}"
    # default schema
    if [ "${KIE_SERVER_PERSISTENCE_SCHEMA}" != "" ]; then
        JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.persistence.schema=${KIE_SERVER_PERSISTENCE_SCHEMA}"
    fi
}

function configure_server_security() {
    # add eap users (see bpmsuite-security.sh)
    add_kie_admin_user
    add_kie_server_user
    # user/pwd
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.user=$(get_kie_server_user)"
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.pwd=$(get_kie_server_pwd)"
    # token
    local kieServerToken="$(get_kie_server_token)"
    if [ "${kieServerToken}" != "" ]; then
        JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.token=${kieServerToken}"
    fi
    # domain
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.domain=$(get_kie_server_domain)"
    # bypass auth user
    local kieServerBypassAuthUser="$(get_kie_server_bypass_auth_user)"
    if [ "${kieServerBypassAuthUser}" != "" ]; then
        JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.bypass.auth.user=${kieServerBypassAuthUser}"
    fi
}

function configure_server_sync_deploy() {
    # server sync deploy (true by default)
    local kieServerSyncDeploy="true";
    if [ "${KIE_SERVER_SYNC_DEPLOY// /}" != "" ]; then
        kieServerSyncDeploy=$(echo "${KIE_SERVER_SYNC_DEPLOY}" | tr "[:upper:]" "[:lower:]")
        if [ "${kieServerSyncDeploy}" != "true" ]; then
            kieServerSyncDeploy="false"
        fi
    fi
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.sync.deploy=${kieServerSyncDeploy}"
}

function configure_executor() {
    # kie executor number of retries
    if [ "${KIE_EXECUTOR_RETRIES}" != "" ]; then
        JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.executor.retry.count=${KIE_EXECUTOR_RETRIES}"
    fi
}

# Enable/disable the jbpm capabilities according with the product
function configure_jbpm() {
    if [[ $JBOSS_PRODUCT =~ (bpmsuite\-execution|rhpam\-kie)server ]]; then
        JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.jbpm.ejb.timer.tx=true"
        if [ "${JBPM_HT_CALLBACK_METHOD}" != "" ]; then
            JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.jbpm.ht.callback=${JBPM_HT_CALLBACK_METHOD}"
        fi
        if [ "${JBPM_HT_CALLBACK_CLASS}" != "" ]; then
            JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.jbpm.ht.custom.callback=${JBPM_HT_CALLBACK_CLASS}"
        fi
        if [ "${JBPM_LOOP_LEVEL_DISABLED}" != "" ]; then
            # yes, this starts with -Djbpm not -Dorg.jbpm
            JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Djbpm.loop.level.disabled=${JBPM_LOOP_LEVEL_DISABLED}"
        fi
    elif [ "${JBOSS_PRODUCT}" = "rhdm-kieserver" ]; then
        JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.jbpm.server.ext.disabled=true -Dorg.jbpm.ui.server.ext.disabled=true -Dorg.jbpm.case.server.ext.disabled=true"
    fi
}

function configure_kie_server_mgmt() {

    local ALLOWED_STARTUP_STRATEGY=("LocalContainersStartupStrategy" "ControllerBasedStartupStrategy")
    local invalidStrategy=true

    # setting valid for both, rhpam and rhdm execution server
    if [ "${KIE_SERVER_MGMT_DISABLED^^}" = "TRUE" ]; then
        JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.mgmt.api.disabled=true"
    fi

    if [ "x${KIE_SERVER_STARTUP_STRATEGY}" != "x" ]; then
        for strategy in ${ALLOWED_STARTUP_STRATEGY[@]}; do
            if [ "$strategy" = "${KIE_SERVER_STARTUP_STRATEGY}" ]; then
                invalidStrategy=false
                JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.startup.strategy=${KIE_SERVER_STARTUP_STRATEGY}"
            fi
        done

        if [ "$invalidStrategy" = "true" ]; then
            log_warning "The startup strategy ${KIE_SERVER_STARTUP_STRATEGY} is not valid, the valid strategies are LocalContainersStartupStrategy and ControllerBasedStartupStrategy"
        fi
    fi
}

function configure_server_state() {
    # Need to replace whitespaces with something different from space or escaped space (\ ) characters
    local kieServerId="${KIE_SERVER_ID// /_}"
    if [ "${kieServerId}" = "" ]; then
        if [ "x${HOSTNAME}" != "x" ]; then
            # chop off trailing unique "dash number" so all servers use the same template
            kieServerId=$(echo "${HOSTNAME}" | sed -e 's/\(.*\)-[[:digit:]]\+-.*/\1/')
        else
            kieServerId="$(generate_random_id)"
        fi
    fi
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.id=${kieServerId}"

    # see scripts/os.bpmsuite.executionserver/configure.sh
    local kieServerRepo="${HOME}/.kie/repository"
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.repo=${kieServerRepo}"

    # see above: configure_server_env / kieserver-env.sh / setKieEnv
    if [ "${KIE_SERVER_CONTAINER_DEPLOYMENT}" != "" ]; then
        # ensure all KIE dependencies are pulled for offline use (this duplicates s2i process; TODO: short-circuit if possible?)
        $JBOSS_HOME/bin/launch/kieserver-pull.sh
        ERR=$?
        if [ $ERR -ne 0 ]; then
            log_error "Aborting due to error code $ERR from maven kjar dependency pull"
            exit $ERR
        fi

        # verify all KIE containers (this duplicates s2i process; TODO: short-circuit if possible?)
        $JBOSS_HOME/bin/launch/kieserver-verify.sh
        ERR=$?
        if [ $ERR -ne 0 ]; then
            log_error "Aborting due to error code $ERR from maven kjar verification"
            exit $ERR
        fi

        # create a KIE server state file with all configured containers and properties
        local stateFileInit="org.kie.server.services.impl.storage.file.KieServerStateFileInit"
        log_info "Attempting to generate kie server state file with 'java ${JBOSS_BPMSUITE_ARGS} ${stateFileInit}'"
        java ${JBOSS_BPMSUITE_ARGS} $(getKieJavaArgs) ${stateFileInit}
        ERR=$?
        if [ $ERR -ne 0 ]; then
            log_error "Aborting due to error code $ERR from kie server state file init"
            exit $ERR
        fi
    fi
}

function generate_random_id() {
    cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1
}
