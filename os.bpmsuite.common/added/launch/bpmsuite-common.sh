#!/bin/bash

source "${JBOSS_HOME}/bin/launch/launch-common.sh"
source /usr/local/s2i/scl-enable-maven
source $JBOSS_HOME/bin/launch/logging.sh

function prepareEnv() {
    # please keep these in alphabetical order
    unset KIE_ADMIN_PWD
    unset KIE_ADMIN_ROLES
    unset KIE_ADMIN_USER
    unset KIE_MBEANS
    unset KIE_SERVER_CONTROLLER_PWD
    unset KIE_SERVER_CONTROLLER_ROLES
    unset KIE_SERVER_CONTROLLER_USER
    unset MAVEN_REPO_PASSWORD
    unset MAVEN_REPO_ROLES
    unset MAVEN_REPO_USERNAME
}

function configureEnv() {
    configure
}

function configure() {
    configure_admin_security
    configure_controller_security
    configure_maven_security
    configure_maven_settings
    configure_mbeans
}

function configure_admin_security() {
    local kieAdminUser=$(find_env "KIE_ADMIN_USER" "adminUser")
    local kieAdminPwd=$(find_env "KIE_ADMIN_PWD" "admin1!")
    local kieAdminRoles=$(find_env "KIE_ADMIN_ROLES" "kie-server,rest-all,admin,kiemgmt,Administrators")
    add_eap_user "admin" "${kieAdminUser}" "${kieAdminPwd}" "${kieAdminRoles}"
}

function configure_controller_security() {
    local kieServerControllerUser=$(find_env "KIE_SERVER_CONTROLLER_USER" "controllerUser")
    local kieServerControllerPwd=$(find_env "KIE_SERVER_CONTROLLER_PWD" "controller1!")
    local kieServerControllerRoles=$(find_env "KIE_SERVER_CONTROLLER_ROLES" "kie-server,rest-all,guest")
    add_eap_user "controller" "${kieServerControllerUser}" "${kieServerControllerPwd}" "${kieServerControllerRoles}"
}

function configure_maven_security() {
    # we will only create a default maven user if no single nor multi maven username(s) were specified
    local default_mavenRepoUsername="mavenUser"
    # multiple repos scenario
    IFS=',' read -a multi_mavenRepoPrefixes <<< ${MAVEN_REPOS}
    for multi_mavenRepoPrefix in ${multi_mavenRepoPrefixes[@]}; do
        multi_mavenRepoPrefix=${multi_mavenRepoPrefix^^}
        multi_mavenRepoPrefix=${multi_mavenRepoPrefix//-/_}
        local multi_mavenRepoUsername=$(find_env "${multi_mavenRepoPrefix}_MAVEN_REPO_USERNAME")
        if [ "x${multi_mavenRepoUsername}" != "x" ]; then
            local multi_mavenRepoPassword=$(find_env "${multi_mavenRepoPrefix}_MAVEN_REPO_PASSWORD" "maven1!")
            local multi_mavenRepoRoles=$(find_env "${multi_mavenRepoPrefix}_MAVEN_REPO_ROLES")
            add_eap_user "maven" "${multi_mavenRepoUsername}" "${multi_mavenRepoPassword}" "${multi_mavenRepoRoles}"
            default_mavenRepoUsername=""
        fi
    done
    # single repo scenario
    local single_mavenRepoUsername=$(find_env "MAVEN_REPO_USERNAME" "${default_mavenRepoUsername}")
    if [ "x${single_mavenRepoUsername}" != "x" ]; then
        local single_mavenRepoPassword=$(find_env "MAVEN_REPO_PASSWORD" "maven1!")
        local single_mavenRepoRoles=$(find_env "MAVEN_REPO_ROLES")
        add_eap_user "maven" "${single_mavenRepoUsername}" "${single_mavenRepoPassword}" "${single_mavenRepoRoles}"
    fi
}

function add_eap_user() {
    local eapType="${1}"
    local eapUser="${2}"
    local eapPwd="${3}"
    local eapRoles="${4}"
    if [ "x${eapRoles}" != "x" ]; then
        ${JBOSS_HOME}/bin/add-user.sh -a --user "${eapUser}" --password "${eapPwd}" --role "${eapRoles}"
    else
        ${JBOSS_HOME}/bin/add-user.sh -a --user "${eapUser}" --password "${eapPwd}"
    fi
    if [ "$?" -ne "0" ]; then
        log_error "Failed to create ${eapType} user \"${eapUser}\""
        log_error "Exiting..."
        exit
    fi
}

function configure_maven_settings() {
    # env var used by KIE to first find and load global settings.xml
    local m2Home=$(mvn -v | grep -i 'maven home: ' | sed -E 's/^.{12}//')
    export M2_HOME="${m2Home}"
    # see scripts/os.bpmsuite.common/configure.sh
    # used by KIE to then override with custom settings.xml
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dkie.maven.settings.custom=${HOME}/.m2/settings.xml"
}

function configure_mbeans() {
    # should jmx mbeans be enabled? (true/false becomes enabled/disabled)
    if [ "x${KIE_MBEANS}" != "x" ]; then
        # if specified, respect value
        local kieMbeans=$(echo "${KIE_MBEANS}" | tr "[:upper:]" "[:lower:]")
        if [ "${kieMbeans}" = "true" ] || [ "${kieMbeans}" = "enabled" ]; then
            KIE_MBEANS="enabled"
        else
            KIE_MBEANS="disabled"
        fi
    else
        # otherwise, default to enabled
        KIE_MBEANS="enabled"
    fi
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dkie.mbeans=${KIE_MBEANS} -Dkie.scanner.mbeans=${KIE_MBEANS}"
}

