#!/bin/bash

source /usr/local/s2i/scl-enable-maven
source "${JBOSS_HOME}/bin/launch/jboss-kie-security-ldap.sh"

function prepareEnv() {
    # please keep these in alphabetical order
    unset KIE_MBEANS
    unset_kie_security_ldap_env
}

function configureEnv() {
    configure
}

function configure() {
    configure_maven_settings
    configure_mbeans
    configure_ldap_security_domain
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
