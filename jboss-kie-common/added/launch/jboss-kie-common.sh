#!/bin/bash

source /usr/local/s2i/scl-enable-maven
source "${JBOSS_HOME}/bin/launch/jboss-kie-security-login-modules.sh"

function prepareEnv() {
    # please keep these in alphabetical order
    unset KIE_MBEANS
    unset_kie_security_auth_env
}

function configureEnv() {
    configure
}

function configure() {
    configure_maven_settings
    configure_mbeans
    configure_auth_login_modules
}

function configure_maven_settings() {
    # env var used by KIE to first find and load global settings.xml
    local m2Home=$(mvn -v | grep -i 'maven home: ' | sed -E 's/^.{12}//')
    export M2_HOME="${m2Home}"
    # see scripts/jboss-kie-common/configure.sh
    # used by KIE to then override with custom settings.xml
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dkie.maven.settings.custom=${HOME}/.m2/settings.xml"
}

function configure_mbeans() {
    # should jmx mbeans be enabled? (true/false becomes enabled/disabled)
    local kieMbeans="enabled"
    if [ "x${KIE_MBEANS}" != "x" ]; then
        # if specified, respect value
        local km=$(echo "${KIE_MBEANS}" | tr "[:upper:]" "[:lower:]")
        if [ "${km}" != "true" ] && [ "${km}" != "enabled" ]; then
            kieMbeans="disabled"
        fi
    fi
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dkie.mbeans=${kieMbeans} -Dkie.scanner.mbeans=${kieMbeans}"
}

# ${1} - routeName
# sets the response from kubernetes api.
query_server_host() {

    # only execute the following lines if this container is running on OpenShift
    if [ -e /var/run/secrets/kubernetes.io/serviceaccount/token ]; then
        local namespace=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
        local token=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
        local response=$(curl -s -w "%{http_code}" --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
            -H "Authorization: Bearer $token" \
            -H 'Accept: application/json' \
            https://${KUBERNETES_SERVICE_HOST:-kubernetes.default.svc}:${KUBERNETES_SERVICE_PORT:-443}/apis/route.openshift.io/v1/namespaces/${namespace}/routes/${1})
        echo ${response}
    fi
}