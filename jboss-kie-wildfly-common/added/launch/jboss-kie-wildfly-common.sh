#!/bin/bash

source "${JBOSS_HOME}/bin/launch/logging.sh"

function prepareEnv() {
    # please keep these in alphabetical order
    unset KIE_MBEANS
    unset_kie_security_auth_env
}

function configureEnv() {
    configure
}

function configure() {
    configure_mem_ratio
    configure_mbeans
    #configure_auth_login_modules
}

function configure_mem_ratio() {
    export JAVA_MAX_MEM_RATIO=${JAVA_MAX_MEM_RATIO:-80}
    export JAVA_INITIAL_MEM_RATIO=${JAVA_INITIAL_MEM_RATIO:-25}
}

function configure_maven_settings() {
    # env var used by KIE to first find and load global settings.xml
    local m2Home=$(mvn -v | grep -i 'maven home: ' | sed -E 's/^.{12}//')
    export M2_HOME="${m2Home}"

    # KIECLOUD-304
    local mavenSettings="${HOME}/.m2/settings.xml"
    # maven module already takes care if the provided file exist, if a non existent file or directory is set
    # it will automatically fallback to the default settings.xml
    if [ ! -z "${MAVEN_SETTINGS_XML}" -a "${MAVEN_SETTINGS_XML}" != "${mavenSettings}" ]; then
        log_info "Custom maven settings provided, validating ${MAVEN_SETTINGS_XML}."
        validationResult=$(mvn help:effective-settings -s "${MAVEN_SETTINGS_XML}")
        if [ $? -eq 0 ]; then
            mavenSettings="${MAVEN_SETTINGS_XML}"
        else
            log_error "$validationResult"
            log_info "Falling back to ${mavenSettings}"
        fi
    fi
    # see scripts/jboss-kie-wildfly-common/configure.sh
    # used by KIE to then override with custom settings.xml
    JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dkie.maven.settings.custom=${mavenSettings}"
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
