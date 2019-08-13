#!/bin/bash

source "${JBOSS_HOME}/bin/launch/launch-common.sh"
source "${JBOSS_HOME}/bin/launch/logging.sh"

########## Environment Variables ##########

function unset_kie_security_env() {
    # please keep these in alphabetical order
    unset APPLICATION_USERS_PROPERTIES
    unset APPLICATION_ROLES_PROPERTIES
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
    local default_kie_roles="kie-server,rest-all,user"
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
    local default_kie_roles="kie-server,rest-all,user"
    echo $(find_env "KIE_SERVER_CONTROLLER_ROLES" "${default_kie_roles}")
}

function add_kie_server_controller_user() {
    add_eap_user "controller" "$(get_kie_server_controller_user)" "$(get_kie_server_controller_pwd)" "$(get_kie_server_controller_roles)"
}


# print information if the users creation is skipped
# This function only have the purpose to print user information based on product
# to guide the user about what users they need to create on the external auth provider, if enabled.
#
# $1 - type/component
print_user_information() {
    if [ "${AUTH_LDAP_URL}x" != "x" ] || [ "${SSO_URL}x" != "x" ]; then
        log_info "External authentication/authorization enabled, skipping the embedded users creation."
        if [ "${1}" == "kieadmin" ] || [ "${1}" == "central" ] || [ "${1}" == "kieserver" ]; then
            if [ "${KIE_ADMIN_USER}x" != "x" ]; then
                log_info "KIE_ADMIN_USER is set to ${KIE_ADMIN_USER}, make sure to configure this user with the provided password on the external auth provider with the roles $(get_kie_admin_roles)"
            else
                log_info "Make sure to configure a ADMIN user to access the Business Central with the roles $(get_kie_admin_roles)"
            fi
        fi

        if [ "${1}" == "central" ] || [ "${1}" == "kieserver" ]; then
            if [ "${KIE_MAVEN_USER}x" != "x"  ]; then
                log_info "KIE_MAVEN_USER is set to ${KIE_MAVEN_USER}, make sure to configure this user with the provided password on the external auth provider."
            else
                log_info "Make sure to configure the KIE_MAVEN_USER user to interact with Business Central embedded maven server"
            fi

        fi

        if [ "${1}" == "central" ] || [ "${1}" == "kieserver" ] || [ "${1}" == "controller" ]; then
            if [ "${KIE_SERVER_CONTROLLER_USER}x" != "x" ]; then
                log_info "KIE_SERVER_CONTROLLER_USER is set to ${KIE_SERVER_CONTROLLER_USER}, make sure to configure this user with the provided password on the external auth provider with the roles $(get_kie_server_controller_roles)"
            else
                log_info "Make sure to configure the KIE_SERVER_CONTROLLER_USER user to interact with KIE Server rest api with the roles $(get_kie_server_controller_roles)"
            fi

        fi

        if [ "${1}" == "kieserver" ] || [ "${1}" == "controller" ]; then
            if [ "${KIE_SERVER_USER}x" != "x" ]; then
                log_info "KIE_SERVER_USER is set to ${KIE_SERVER_USER}, make sure to configure this user with the provided password on the external auth provider with the roles $(get_kie_server_roles)"
            else
                log_info "Make sure to configure the KIE_SERVER_USER user to interact with KIE Server rest api with the roles $(get_kie_server_roles)"
            fi
        fi
    fi

}

########## EAP ##########

function get_application_config() {
    local props_file="${1}"
    local default_file="${2}"
    local default_content="${3}"
    if [ "x${props_file}" = "x" ]; then
        props_file="${JBOSS_HOME}/standalone/configuration/${default_file}"
    fi
    local props_dir=$(dirname "${props_file}")
    if [ ! -e "${props_dir}" ]; then
        mkdir -p "${props_dir}"
    fi
    if [ ! -f "${props_file}" ]; then
        if [ "x${default_content}" = "x" ]; then
            touch "${props_file}"
        else
            echo "${default_content}" > "${props_file}"
        fi
    fi
    echo "${props_file}"
}

function get_application_users_properties() {
    local application_users_properties=$(get_application_config "${APPLICATION_USERS_PROPERTIES}" "application-users.properties" '#$REALM_NAME=ApplicationRealm$')
    echo "${application_users_properties}"
}

function get_application_roles_properties() {
    echo $(get_application_config "${APPLICATION_ROLES_PROPERTIES}" "application-roles.properties")
}

function set_application_users_config() {
    if [ -n "${APPLICATION_USERS_PROPERTIES}" ]; then
        local application_users_properties="$(get_application_users_properties)"
        local config_file="${JBOSS_HOME}/standalone/configuration/standalone-openshift.xml"
        sed -i "s,path=\"application-users.properties\" relative-to=\"jboss.server.config.dir\",path=\"${application_users_properties}\",g" "${config_file}"
    fi
}

function set_application_roles_config() {
    if [ -n "${APPLICATION_ROLES_PROPERTIES}" ]; then
        local application_roles_properties="$(get_application_roles_properties)"
        local config_file="${JBOSS_HOME}/standalone/configuration/standalone-openshift.xml"
        sed -i "s,path=\"application-roles.properties\" relative-to=\"jboss.server.config.dir\",path=\"${application_roles_properties}\",g" "${config_file}"
    fi
}

function add_eap_user() {
    # If LDAP/SSO integration is enabled, do not create eap users.
     if [ "${AUTH_LDAP_URL}x" == "x" ] && [ "${SSO_URL}x" == "x" ]; then
        local kie_type="${1}"
        local eap_user="${2}"
        local eap_pwd="${3}"
        local eap_roles="${4}"
        local application_users_properties="$(get_application_users_properties)"
        local application_roles_properties="$(get_application_roles_properties)"
        if (grep "^${eap_user}=" "${application_users_properties}" > /dev/null 2>&1); then
            log_warning "KIE ${kie_type} user \"${eap_user}\" already exists in EAP"
            log_warning "Skipping..."
        else
            local add_user_args=(
                "-a"
                "--user" "${eap_user}"
                "--password" "${eap_pwd}"
            )
            add_user_args+=( "--user-properties" "${application_users_properties}" )
            add_user_args+=( "--group-properties" "${application_roles_properties}" )
            if [ "x${eap_roles}" != "x" ]; then
                add_user_args+=( "--role" "${eap_roles}" )
            fi
            ${JBOSS_HOME}/bin/add-user.sh ${add_user_args[@]}
            if [ "$?" -ne "0" ]; then
                log_error "Failed to add KIE ${kie_type} user \"${eap_user}\" in EAP"
                log_error "Exiting..."
                exit
            fi
        fi
    fi
}
