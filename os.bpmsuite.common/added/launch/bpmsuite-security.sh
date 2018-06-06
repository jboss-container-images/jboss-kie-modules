#!/bin/bash

source "${JBOSS_HOME}/bin/launch/launch-common.sh"
source "${JBOSS_HOME}/bin/launch/logging.sh"

########## Environment Variables ##########

function unset_kie_security_env() {
    # please keep these in alphabetical order
    unset KIE_ADMIN_PWD
    unset KIE_ADMIN_ROLES
    unset KIE_ADMIN_USER
    unset KIE_MAVEN_PWD
    unset KIE_MAVEN_ROLES
    unset KIE_MAVEN_USER
    unset KIE_SERVER_BYPASS_AUTH_USER
    unset KIE_SERVER_CONTROLLER_PWD
    unset KIE_SERVER_CONTROLLER_ROLES
    unset KIE_SERVER_CONTROLLER_TOKEN
    unset KIE_SERVER_CONTROLLER_USER
    unset KIE_SERVER_DOMAIN
    unset KIE_SERVER_PWD
    unset KIE_SERVER_ROLES
    unset KIE_SERVER_TOKEN
    unset KIE_SERVER_USER
}

########## Defaults ##########

function get_default_kie_user() {
    local kie_type="${1}"
    echo "${kie_type}User"
}

function get_default_kie_pwd() {
    local kie_type="${1}"
    echo "${kie_type}1!"
}

function esc_kie_pwd() {
    local kie_pwd="${1}"
    echo ${kie_pwd//\"/\\\"}
}

########## KIE Admin ##########

function get_kie_admin_user() {
    local default_kie_user=$(get_default_kie_user "admin")
    echo $(find_env "KIE_ADMIN_USER" "${default_kie_user}")
}

function get_kie_admin_pwd() {
    local default_kie_pwd=$(get_default_kie_pwd "admin")
    echo $(find_env "KIE_ADMIN_PWD" "${default_kie_pwd}")
}

function esc_kie_admin_pwd() {
    local orig_kie_pwd=$(get_kie_admin_pwd)
    echo $(esc_kie_pwd "${orig_kie_pwd}")
}

function get_kie_admin_roles() {
    local default_kie_roles="kie-server,rest-all,admin,kiemgmt,Administrators"
    echo $(find_env "KIE_ADMIN_ROLES" "${default_kie_roles}")
}

function add_kie_admin_user() {
    add_eap_user "admin" "$(get_kie_admin_user)" "$(get_kie_admin_pwd)" "$(get_kie_admin_roles)"
}

########## KIE Maven ##########

function get_kie_maven_user() {
    local default_kie_user=$(get_default_kie_user "maven")
    echo $(find_env "KIE_MAVEN_USER" "${default_kie_user}")
}

function get_kie_maven_pwd() {
    local default_kie_pwd=$(get_default_kie_pwd "maven")
    echo $(find_env "KIE_MAVEN_PWD" "${default_kie_pwd}")
}

function esc_kie_maven_pwd() {
    local orig_kie_pwd=$(get_kie_maven_pwd)
    echo $(esc_kie_pwd "${orig_kie_pwd}")
}

function get_kie_maven_roles() {
    local default_kie_roles=""
    echo $(find_env "KIE_MAVEN_ROLES" "${default_kie_roles}")
}

function add_kie_maven_user() {
    add_eap_user "maven" "$(get_kie_maven_user)" "$(get_kie_maven_pwd)" "$(get_kie_maven_roles)"
}

########## KIE Server ##########

function get_kie_server_user() {
    local default_kie_user=$(get_default_kie_user "execution")
    echo $(find_env "KIE_SERVER_USER" "${default_kie_user}")
}

function get_kie_server_pwd() {
    local default_kie_pwd=$(get_default_kie_pwd "execution")
    echo $(find_env "KIE_SERVER_PWD" "${default_kie_pwd}")
}

function esc_kie_server_pwd() {
    local orig_kie_pwd=$(get_kie_server_pwd)
    echo $(esc_kie_pwd "${orig_kie_pwd}")
}

function get_kie_server_token() {
    local default_kie_token=""
    echo $(find_env "KIE_SERVER_TOKEN" "${default_kie_token}")
}

function get_kie_server_roles() {
    local default_kie_roles="kie-server,rest-all,guest"
    echo $(find_env "KIE_SERVER_ROLES" "${default_kie_roles}")
}

function get_kie_server_domain() {
    local default_kie_domain="other"
    echo $(find_env "KIE_SERVER_DOMAIN" "${default_kie_domain}")
}

function get_kie_server_bypass_auth_user() {
    local bypass_auth_user=$(echo "${KIE_SERVER_BYPASS_AUTH_USER}" | tr "[:upper:]" "[:lower:]")
    if [ "x${bypass_auth_user}" != "x" ] && [ "${bypass_auth_user}" != "true" ]; then
        bypass_auth_user="false"
    fi
    echo "${bypass_auth_user}"
}

function add_kie_server_user() {
    add_eap_user "execution" "$(get_kie_server_user)" "$(get_kie_server_pwd)" "$(get_kie_server_roles)"
}

########## KIE Server Controller ##########

function get_kie_server_controller_user() {
    local default_kie_user=$(get_default_kie_user "controller")
    echo $(find_env "KIE_SERVER_CONTROLLER_USER" "${default_kie_user}")
}

function get_kie_server_controller_pwd() {
    local default_kie_pwd=$(get_default_kie_pwd "controller")
    echo $(find_env "KIE_SERVER_CONTROLLER_PWD" "${default_kie_pwd}")
}

function esc_kie_server_controller_pwd() {
    local orig_kie_pwd=$(get_kie_server_controller_pwd)
    echo $(esc_kie_pwd "${orig_kie_pwd}")
}

function get_kie_server_controller_token() {
    local default_kie_token=""
    echo $(find_env "KIE_SERVER_CONTROLLER_TOKEN" "${default_kie_token}")
}

function get_kie_server_controller_roles() {
    local default_kie_roles="kie-server,rest-all,guest"
    echo $(find_env "KIE_SERVER_CONTROLLER_ROLES" "${default_kie_roles}")
}

function add_kie_server_controller_user() {
    add_eap_user "controller" "$(get_kie_server_controller_user)" "$(get_kie_server_controller_pwd)" "$(get_kie_server_controller_roles)"
}

########## EAP ##########

function add_eap_user() {
    local kie_type="${1}"
    local eap_user="${2}"
    local eap_pwd="${3}"
    local eap_roles="${4}"
    if [ "x${eap_roles}" != "x" ]; then
        ${JBOSS_HOME}/bin/add-user.sh -a --user "${eap_user}" --password "${eap_pwd}" --role "${eap_roles}"
    else
        ${JBOSS_HOME}/bin/add-user.sh -a --user "${eap_user}" --password "${eap_pwd}"
    fi
    if [ "$?" -ne "0" ]; then
        log_error "Failed to add KIE ${kie_type} user \"${eap_user}\" in EAP"
        log_error "Exiting..."
        exit
    fi
}
