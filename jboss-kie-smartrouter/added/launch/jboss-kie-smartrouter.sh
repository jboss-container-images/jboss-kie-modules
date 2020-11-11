#!/bin/bash

source "${LAUNCH_DIR}/launch-common.sh"
source "${LAUNCH_DIR}/logging.sh"
source "${JBOSS_HOME}/bin/launch/jboss-kie-common.sh"

function prepareEnv() {
    # please keep these in alphabetical order
    unset KIE_ADMIN_USER
    unset KIE_ADMIN_PWD
    unset KIE_SERVER_CONTROLLER_HOST
    unset KIE_SERVER_CONTROLLER_PORT
    unset KIE_SERVER_CONTROLLER_PROTOCOL
    unset KIE_SERVER_CONTROLLER_SERVICE
    unset KIE_SERVER_CONTROLLER_TOKEN
    unset KIE_SERVER_ROUTER_HOST
    unset KIE_SERVER_ROUTER_ID
    unset KIE_SERVER_ROUTER_NAME
    unset KIE_SERVER_ROUTER_PORT
    unset KIE_SERVER_ROUTER_PROTOCOL
    unset KIE_SERVER_ROUTER_URL_EXTERNAL
    unset KIE_SERVER_ROUTER_REPO
    unset KIE_SERVER_ROUTER_ROUTE_NAME
    unset KIE_SERVER_ROUTER_SERVICE
    unset KIE_SERVER_ROUTER_CONFIG_WATCHER_ENABLED
    unset KIE_SERVER_ROUTER_TLS_KEYSTORE
    unset KIE_SERVER_ROUTER_TLS_KEYSTORE_PASSWORD
    unset KIE_SERVER_ROUTER_TLS_KEYSTORE_KEYALIAS
    unset KIE_SERVER_ROUTER_PORT_TLS
    unset KIE_SERVER_ROUTER_TLS_TEST
}

function configureEnv() {
    configure
}

function configure() {
    configure_logger_config_file
    configure_mem_ratio
    configure_router_state
    configure_router_location
    configure_controller_access
    configure_router_tls
}

function configure_mem_ratio() {
    export JAVA_MAX_MEM_RATIO=${JAVA_MAX_MEM_RATIO:-80}
    export JAVA_INITIAL_MEM_RATIO=${JAVA_INITIAL_MEM_RATIO:-25}
}

function configure_logger_config_file() {
    # JUL implementation: https://docs.oracle.com/javase/7/docs/api/java/util/logging/Level.html
    local allowed_log_levels=("ALL" "CONFIG" "FINE" "FINER" "FINEST" "INFO" "OFF" "SEVERE" "WARNING")
    local config_dir=${CONFIG_DIR:-"/opt/rhpam-smartrouter"}
    # shellcheck disable=SC2153
    if [[ ! "${allowed_log_levels[*]}" =~ ${LOG_LEVEL} ]]; then
        log_warning "Log Level ${LOG_LEVEL} is not allowed, the allowed levels are ${allowed_log_levels[*]}"
    else
        local log_level=${LOG_LEVEL:-INFO}
        sed -i "s/{LOG_LEVEL}/${log_level}/" "${config_dir}"/logging.properties
        local logger_categories=${LOGGER_CATEGORIES//,/\\n}
        sed -i "s/{PACKAGES_LOG_LEVEL}/${logger_categories}/" "${config_dir}"/logging.properties
        log_info "Configuring logger categories ${logger_categories} with level ${log_level}"
        JAVA_OPTS_APPEND="${JAVA_OPTS_APPEND} -Djava.util.logging.config.file=${config_dir}/logging.properties"
    fi
}

function configure_router_state() {
    # replace all non-alphanumeric characters with a dash
    local kieServerRouterId="${KIE_SERVER_ROUTER_ID//[^[:alnum:].-]/-}"
    if [ "x${kieServerRouterId}" != "x" ]; then
        # can't start with a dash
        firstChar="$(echo -n "$kieServerRouterId" | head -c 1)"
        if [ "${firstChar}" = "-" ]; then
            kieServerRouterId="0${kieServerRouterId}"
        fi
        # can't end with a dash
        lastChar="$(echo -n "$kieServerRouterId" | tail -c 1)"
        if [ "${lastChar}" = "-" ]; then
            kieServerRouterId="${kieServerRouterId}0"
        fi
    else
        if [ "x${HOSTNAME}" != "x" ]; then
            # chop off trailing unique "dash number" so all servers use the same template
            kieServerRouterId="${HOSTNAME//\(.*\)-[[:digit:]]\+-.*/\1}"
        else
            kieServerRouterId="$(generate_random_id)"
        fi
    fi
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.router.id=${kieServerRouterId}"

    # Need to replace whitespaces with something different from space or escaped space (\ ) characters
    local kieServerRouterName="${KIE_SERVER_ROUTER_NAME// /_}"
    if [ "${kieServerRouterName}" = "" ]; then
        kieServerRouterName="${kieServerRouterId}"
    fi
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.router.name=${kieServerRouterName}"

    # Potentially allow HA config by watching file system for config changes
    if [ "x${KIE_SERVER_ROUTER_CONFIG_WATCHER_ENABLED}" != "x" ]; then
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.router.config.watcher.enabled=${KIE_SERVER_ROUTER_CONFIG_WATCHER_ENABLED}"
    fi

    # see scripts/jboss-kie-smartrouter/configure.sh
    local kieServerRouterRepo="/opt/${JBOSS_PRODUCT}"

    # Potentially modify the location of smart router data
    if [ "x${KIE_SERVER_ROUTER_REPO}" != "x" ]; then
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.router.repo=${KIE_SERVER_ROUTER_REPO}"
    else
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.router.repo=${kieServerRouterRepo}"
    fi
}

function configure_router_location {

    local routeName="${KIE_SERVER_ROUTER_ROUTE_NAME}"
    local routeService="${KIE_SERVER_ROUTER_SERVICE}"
    local host="${KIE_SERVER_ROUTER_HOST}"
    local port="${KIE_SERVER_ROUTER_PORT}"
    local protocol="${KIE_SERVER_ROUTER_PROTOCOL}"
    local routerUrlExternal="${KIE_SERVER_ROUTER_URL_EXTERNAL}"
    local defaultInsecureHost="${HOSTNAME_HTTP:-${HOSTNAME:-localhost}}"
    local defaultSecureHost="${HOSTNAME_HTTPS:-${defaultInsecureHost}}"

    if [ "${host}" = "" ]; then
        host=$(find_env "${routeService}_SERVICE_HOST")
    fi
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.router.host=${host}"
    if [ "${port}" = "" ]; then
        port=$(find_env "${routeService}_SERVICE_PORT" "9000")
    fi

    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.router.port=${port}"
    if [ -z "${routerUrlExternal}" ]; then
       if [ -n "${routeName}" ]; then
            if [ "${protocol}" = "https" ]; then
                routeName="${routeName}"
                host="${host:-${defaultSecureHost}}"
                port="${port:-443}"
            else
                protocol="${protocol:-http}"
                host="${host:-${defaultInsecureHost}}"
                port="${port:-80}"
            fi

	        routeHost=$(query_route_host "${routeName}" "${host}:${port}")
	        routerUrlExternal="${protocol}://${routeHost}"

       else
            if [ "${protocol}" = "https" ]; then
                host="${host:-${defaultSecureHost}}"
                port="${KIE_SERVER_ROUTER_PORT_TLS:-9443}"
            else
                protocol="${protocol:-http}"
                host="${host:-${defaultInsecureHost}}"
                port="${KIE_SERVER_ROUTER_PORT:-9000}"
            fi
            routerUrlExternal=$(build_simple_url "${protocol}" "${host}" "${port}")
        fi
    fi

    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.router.url.external=${routerUrlExternal}"
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
        kieServerControllerProtocol=$(find_env "KIE_SERVER_CONTROLLER_PROTOCOL" "http")
        # port
        local kieServerControllerPort="${KIE_SERVER_CONTROLLER_PORT}"
        if [ "${kieServerControllerPort}" = "" ]; then
            kieServerControllerPort=$(find_env "${controllerService}_SERVICE_PORT" "8080")
        fi
        # path
        local kieServerControllerPath="/rest/controller"
        if [ "${kieServerControllerProtocol}" = "ws" ]; then
            kieServerControllerPath="/websocket/controller"
        fi
        # url
        local kieServerControllerUrl="${kieServerControllerProtocol}://${kieServerControllerHost}:${kieServerControllerPort}${kieServerControllerPath}"
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.controller=${kieServerControllerUrl}"
    fi
    # NOTE: the below must match what is in jboss-kie-modules/jboss-kie-wildfly-common/added/launch/jboss-kie-wildfly-security.sh
    # user/pwd
    kieServerControllerUser=$(find_env "KIE_ADMIN_USER" "adminUser")
    kieServerControllerPwd=$(find_env "KIE_ADMIN_PWD" "adminPwd1!")
    kieServerControllerPwd=${kieServerControllerPwd//\"/\\\"}
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.controller.user=\"${kieServerControllerUser}\""
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.controller.pwd=\"${kieServerControllerPwd}\""
    # token
    kieServerControllerToken=$(find_env "KIE_SERVER_CONTROLLER_TOKEN")
    if [ "${kieServerControllerToken}" != "" ]; then
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.controller.token=\"${kieServerControllerToken}\""
    fi
}

function configure_router_tls() {
    # If the path, alias, or password is empty exit early and skip https
    if [ -z "${KIE_SERVER_ROUTER_TLS_KEYSTORE}" ] || \
       [ -z "${KIE_SERVER_ROUTER_TLS_KEYSTORE_KEYALIAS}" ] || \
       [ -z "${KIE_SERVER_ROUTER_TLS_KEYSTORE_PASSWORD}" ]; then
        log_warning "Missing value for TLS keystore path, alias, or password, skipping https setup"
	return
    fi

    # generate a keystore for cekit test if the test flag is true and we are not running in OpenShift
    # and there is no keystore file at the designated path
    if [ "${KIE_SERVER_ROUTER_TLS_TEST}" == "true" ] && [ -z "${KUBERNETES_SERVICE_HOST}" ] && ! [ -f "${KIE_SERVER_ROUTER_TLS_KEYSTORE}" ]; then
        log_warning "Container is in test mode and not in OpenShift, generating test certificate"
        keytool -genkey -alias jboss -keyalg RSA -keystore /tmp/keystore.jks -storepass mykeystorepass -keypass mykeystorepass -dname CN=bob
        KIE_SERVER_ROUTER_TLS_KEYSTORE=/tmp/keystore.jks
    fi

    # Allow for optional volume mount or empty secret
    if ! [ -f "${KIE_SERVER_ROUTER_TLS_KEYSTORE}" ]; then
	log_warning "Keystore file ${KIE_SERVER_ROUTER_TLS_KEYSTORE} not found or not a regular file, skipping https setup"
	return
    fi

    # If the keystore is not readable, smartrouter startup will throw an exception
    # resulting in the http port being unavailable as well. So make sure ...
    if keytool -list -alias "${KIE_SERVER_ROUTER_TLS_KEYSTORE_KEYALIAS}" \
	          -storepass "${KIE_SERVER_ROUTER_TLS_KEYSTORE_PASSWORD}" \
	          -keystore ${KIE_SERVER_ROUTER_TLS_KEYSTORE} &> /dev/null;
	  then
	    log_warning "Unable to read TLS keystore, skipping https setup"
	    return
    fi

    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.router.tls.keystore=${KIE_SERVER_ROUTER_TLS_KEYSTORE}"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.router.tls.keystore.keyalias=${KIE_SERVER_ROUTER_TLS_KEYSTORE_KEYALIAS}"
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.router.tls.keystore.password=${KIE_SERVER_ROUTER_TLS_KEYSTORE_PASSWORD}"

    local kieServerRouterPortTLS="${KIE_SERVER_ROUTER_PORT_TLS}"
    if [ "${kieServerRouterPortTLS}" = "" ]; then
        kieServerRouterPortTLS="9443"
    fi
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.router.tls.port=${kieServerRouterPortTLS}"
}

function generate_random_id() {
     env LC_CTYPE=C < /dev/urandom tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1
}
