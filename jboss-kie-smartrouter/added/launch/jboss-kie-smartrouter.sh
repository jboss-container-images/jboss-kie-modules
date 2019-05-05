#!/bin/bash

source "${LAUNCH_DIR}/launch-common.sh"
source "${LAUNCH_DIR}/logging.sh"

#Test2

function prepareEnv() {
    # please keep these in alphabetical order
    unset KIE_SERVER_CONTROLLER_HOST
    unset KIE_SERVER_CONTROLLER_PORT
    unset KIE_SERVER_CONTROLLER_PROTOCOL
    unset KIE_SERVER_CONTROLLER_PWD
    unset KIE_SERVER_CONTROLLER_SERVICE
    unset KIE_SERVER_CONTROLLER_TOKEN
    unset KIE_SERVER_CONTROLLER_USER
    unset KIE_SERVER_ROUTER_HOST
    unset KIE_SERVER_ROUTER_ID
    unset KIE_SERVER_ROUTER_NAME
    unset KIE_SERVER_ROUTER_PORT
    unset KIE_SERVER_ROUTER_PROTOCOL
    unset KIE_SERVER_ROUTER_URL_EXTERNAL
    unset KIE_SERVER_ROUTER_REPO
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

# Queries the Route from the Kubernetes API
# ${1} - route name
query_route() {
    local routeName=${1}
    # only execute the following lines if this container is running on OpenShift
    if [ -e /var/run/secrets/kubernetes.io/serviceaccount/token ]; then
        local namespace=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
        local token=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
        local response=$(curl -s -w "%{http_code}" --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
            -H "Authorization: Bearer $token" \
            -H 'Accept: application/json' \
            https://${KUBERNETES_SERVICE_HOST:-kubernetes.default.svc}:${KUBERNETES_SERVICE_PORT:-443}/apis/route.openshift.io/v1/namespaces/${namespace}/routes/${routeName})
        echo ${response}
    fi
}

# Queries the Route host from the Kubernetes API
# ${1} - route name
# ${2} - default host
query_route_host() {
    local routeName=${1}
    local host=${2}
    if [ "${routeName}" != "" ]; then
        local response=$(query_route "${routeName}")
        if [ "${response: -3}" = "200" ]; then
            # parse the json response to get the route host
            host=$(echo ${response::- 3} | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["spec"]["host"]')
        else
            log_warning "Fail to query the Route using the Kubernetes API, the Service Account might not have the necessary privileges; defaulting to host [${host}]."
            if [ ! -z "${response}" ]; then
                log_warning "Response message: ${response::- 3} - HTTP Status code: ${response: -3}"
            fi
        fi
    fi
    echo "${host}"
}

# Queries the Route service from the Kubernetes API
# ${1} - route name
query_route_service() {
    local routeName=${1}
    local service
    if [ "${routeName}" != "" ]; then
        local response=$(query_route "${routeName}")
        if [ "${response: -3}" = "200" ]; then
            # parse the json response to get the route service
            service=$(echo ${response::- 3} | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["spec"]["to"]["name"]')
        else
            log_warning "Fail to query the Route using the Kubernetes API, the Service Account might not have the necessary privileges."
            if [ ! -z "${response}" ]; then
                log_warning "Response message: ${response::- 3} - HTTP Status code: ${response: -3}"
            fi
        fi
    fi
    echo "${service}"
}

# Queries the Route service host from the Kubernetes API and Environment
# ${1} - route name
query_route_service_host() {
    local routeName=${1}
    local host=${2}
    if [ "${routeName}" != "" ]; then
        local service=$(query_route_service "${routeName}")
        if [ "${service}" != "" ]; then
            service=${service//-/_}
            service=${service^^}
            host=$(find_env "${service}_SERVICE_HOST" "${host}")
        fi
    fi
    echo "${host}"
}

# Builds a simple URL
# ${1} - protocol (default is http)
# ${2} - host (default is $HOSTNAME if possible, or localhost)
# ${3} - port (default is empty)
# ${4} - path (default is empty)
build_simple_url() {
    local protocol=${1:-http}
    local host=${2:-${HOSTNAME:-localhost}}
    local port=${3}
    local path=${4}
    if [ "${port}" != "" ]; then
        port=":${port}"
    fi
    echo "${protocol}://${host}${port}${path}"
}

# Builds a Route URL by querying the Kubernetes API
# ${1} - route name
# ${2} - default protocol
# ${3} - default host
# ${4} - default port
# ${5} - path
build_route_url() {
    local routeName=${1}
    local protocol=${2}
    local host=${3}
    local port=${4}
    local path=${5}
    if [ "${routeName}" != "" ]; then
        if [[ "${routeName},," = *"secure"* ]]; then
            protocol="${protocol:-https}"
            port="${port:-443}"
        fi
        host=$(query_route_host "${routeName}" "${host}")
    fi
    echo $(build_simple_url "${protocol}" "${host}" "${port}" "${path}")
}

function configure() {
    configure_router_state
    configure_router_access
    configure_router_location
    configure_controller_access
    configure_router_tls
}

function configure_router_state() {
    # Need to replace whitespaces with something different from space or escaped space (\ ) characters
    local kieServerRouterId="${KIE_SERVER_ROUTER_ID// /_}"
    if [ "${kieServerRouterId}" = "" ]; then
        if [ "x${HOSTNAME}" != "x" ]; then
            # chop off trailing unique "dash number" so all servers use the same template
            kieServerRouterId=$(echo "${HOSTNAME}" | sed -e 's/\(.*\)-.*/\1/')
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

function configure_router_access {
    local kieServerRouterService="${KIE_SERVER_ROUTER_SERVICE}"
    kieServerRouterService=${kieServerRouterService^^}
    kieServerRouterService=${kieServerRouterService//-/_}
    # host
    local kieServerRouterHost="${KIE_SERVER_ROUTER_HOST}"
    if [ "${kieServerRouterHost}" = "" ]; then
        kieServerRouterHost=$(find_env "${kieServerRouterService}_SERVICE_HOST")
    fi
    if [ "${kieServerRouterHost}" != "" ]; thenconfigure_router_access
        # protocol
        local kieServerRouterProtocol=$(find_env "KIE_SERVER_ROUTER_PROTOCOL" "http")
        # port
        local kieServerRouterPort="${KIE_SERVER_ROUTER_PORT}"
        if [ "${kieServerRouterPort}" = "" ]; then
            kieServerRouterPort=$(find_env "${kieServerRouterService}_SERVICE_PORT" "9000")
        fi
        # url
        local kieServerRouterUrl=$(build_simple_url "${kieServerRouterProtocol}" "${kieServerRouterHost}" "${kieServerRouterPort}" "")
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.router=${kieServerRouterUrl}"
    fi
}

function configure_router_location() {
    local location="${KIE_SERVER_ROUTER_URL_EXTERNAL}"
    if [ -z "${location}" ]; then
        local protocol="${KIE_SERVER_ROUTER_PROTOCOL,,}"
        local host="${KIE_SERVER_ROUTER_HOST}"
        local defaultInsecureHost="${HOSTNAME_HTTP:-${HOSTNAME:-localhost}}"
        local defaultSecureHost="${HOSTNAME_HTTPS:-${defaultInsecureHost}}"
        local port="${KIE_SERVER_PORT}"
        local routeName="${KIE_SERVER_ROUTE_NAME}"
        if [ -n "${routeName}" ]; then
            if [ "${KIE_SERVER_USE_SECURE_ROUTE_NAME^^}" = "TRUE" ]; then
                routeName="secure-${routeName}"
                protocol="${protocol:-https}"
                host="${host:-${defaultSecureHost}}"
                port="${port:-443}"
            else
                protocol="${protocol:-http}"
                host="${host:-${defaultInsecureHost}}"
                port="${port:-80}"
            fi
            location=$(build_route_url "${routeName}" "${protocol}" "${host}" "${port}")
        else
            if [ "${protocol}" = "https" ]; then
                host="${host:-${defaultSecureHost}}"
                port="${port:-8443}"
            else
                protocol="${protocol:-http}"
                host="${host:-${defaultInsecureHost}}"
                port="${port:-8080}"
            fi
            location=$(build_simple_url "${protocol}" "${host}" "${port}" "${path}")
        fi
    fi
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.router.url.external=${location}"
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
    local kieServerControllerUser=$(find_env "KIE_SERVER_CONTROLLER_USER" "controllerUser")
    local kieServerControllerPwd=$(find_env "KIE_SERVER_CONTROLLER_PWD" "controller1!")
    kieServerControllerPwd=${kieServerControllerPwd//\"/\\\"}
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.controller.user=\"${kieServerControllerUser}\""
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.controller.pwd=\"${kieServerControllerPwd}\""
    # token
    local kieServerControllerToken=$(find_env "KIE_SERVER_CONTROLLER_TOKEN")
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
    keytool -list -alias ${KIE_SERVER_ROUTER_TLS_KEYSTORE_KEYALIAS} \
	          -storepass ${KIE_SERVER_ROUTER_TLS_KEYSTORE_PASSWORD} \
	          -keystore ${KIE_SERVER_ROUTER_TLS_KEYSTORE} &> /dev/null
    if [ "$?" -ne 0 ]; then
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
    cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1
}
