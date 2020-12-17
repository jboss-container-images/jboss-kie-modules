#!/bin/bash

########## Environment Variables ##########

function unset_kie_security_auth_env() {
    # please keep these in alphabetical order
    unset AUTH_LDAP_ALLOW_EMPTY_PASSWORDS
    unset AUTH_LDAP_BASE_CTX_DN
    unset AUTH_LDAP_BASE_FILTER
    unset AUTH_LDAP_BIND_CREDENTIAL
    unset AUTH_LDAP_BIND_DN
    unset AUTH_LDAP_DEFAULT_ROLE
    unset AUTH_LDAP_DISTINGUISHED_NAME_ATTRIBUTE
    unset AUTH_LDAP_JAAS_SECURITY_DOMAIN
    unset AUTH_LDAP_LOGIN_MODULE
    unset AUTH_LDAP_PARSE_ROLE_NAME_FROM_DN
    unset AUTH_LDAP_PARSE_USERNAME
    unset AUTH_LDAP_REFERRAL_USER_ATTRIBUTE_ID_TO_CHECK
    unset AUTH_LDAP_ROLE_ATTRIBUTE_ID
    unset AUTH_LDAP_ROLE_ATTRIBUTE_IS_DN
    unset AUTH_LDAP_ROLE_FILTER
    unset AUTH_LDAP_ROLE_NAME_ATTRIBUTE_ID
    unset AUTH_LDAP_ROLE_RECURSION
    unset AUTH_LDAP_ROLES_CTX_DN
    unset AUTH_LDAP_SEARCH_SCOPE
    unset AUTH_LDAP_SEARCH_TIME_LIMIT
    unset AUTH_LDAP_URL
    unset AUTH_LDAP_USERNAME_BEGIN_STRING
    unset AUTH_LDAP_USERNAME_END_STRING
    unset AUTH_ROLE_MAPPER_REPLACE_ROLE
    unset AUTH_ROLE_MAPPER_ROLES_PROPERTIES
}

function build_login_module() {
    local code=$1
    local flag=$2
    local module=$3

    local login_module=''
    if [[ -n ${module} ]]; then
        login_module="<login-module code=\""${code}"\" flag=\""${flag}"\" module=\""${module}"\">"
    else
        login_module="<login-module code=\""${code}"\" flag=\""${flag}"\">"
    fi
    echo "${login_module}"'<!-- ##LOGIN_MODULE_OPTIONS## --></login-module>'
}

function add_option() {
    local login_module=$1
    local name=$2
    local value=$3
    if [[ ! -z ${value} ]]; then
        echo ${login_module/<!-- ##LOGIN_MODULE_OPTIONS## -->/<module-option name=\"${name}\" value=\"${value}\"/><!-- ##LOGIN_MODULE_OPTIONS## -->}
    else
        echo ${login_module}
    fi
}

function add_login_module() {
    local login_module=$1
    login_module="${login_module/<!-- ##LOGIN_MODULE_OPTIONS## -->/}"
    sed -i "s|<!-- ##OTHER_LOGIN_MODULES## -->|${login_module}<!-- ##OTHER_LOGIN_MODULES## -->|" "${CONFIG_FILE}"
}

function configure_ldap_login_module() {
    if [[ -z ${AUTH_LDAP_URL} ]]; then
        log_info "AUTH_LDAP_URL not set. Skipping LDAP integration..."
        return
    fi
    log_info "AUTH_LDAP_URL is set to ${AUTH_LDAP_URL}. Added LdapExtended login-module"

    # RHPAM-1422, if the RealmDirect is set as Required, ldap auth will fail.
    # TODO remove it out as part of the CLOUD-2750
    sed -i 's|<login-module code="RealmDirect" flag="required">|<login-module code="RealmDirect" flag="optional">|' "${CONFIG_FILE}"
    local ldap_login_module_flag="${AUTH_LDAP_LOGIN_MODULE:-required}"
    if [ "${ldap_login_module_flag}" = "optional" ]; then
        ldap_login_module_flag="optional"
    fi
    local login_module=$(build_login_module "LdapExtended" "${ldap_login_module_flag}")
    login_module=$(add_option "$login_module" "java.naming.provider.url" "${AUTH_LDAP_URL}")
    login_module=$(add_option "$login_module" "jaasSecurityDomain" "${AUTH_LDAP_JAAS_SECURITY_DOMAIN}")
    login_module=$(add_option "$login_module" "bindDN" "${AUTH_LDAP_BIND_DN}")
    login_module=$(add_option "$login_module" "bindCredential" "${AUTH_LDAP_BIND_CREDENTIAL}")
    login_module=$(add_option "$login_module" "baseCtxDN" "${AUTH_LDAP_BASE_CTX_DN}")
    login_module=$(add_option "$login_module" "baseFilter" "${AUTH_LDAP_BASE_FILTER}")
    login_module=$(add_option "$login_module" "rolesCtxDN" "${AUTH_LDAP_ROLES_CTX_DN}")
    login_module=$(add_option "$login_module" "roleFilter" "${AUTH_LDAP_ROLE_FILTER}")
    login_module=$(add_option "$login_module" "roleAttributeID" "${AUTH_LDAP_ROLE_ATTRIBUTE_ID}")
    login_module=$(add_option "$login_module" "roleAttributeIsDN" "${AUTH_LDAP_ROLE_ATTRIBUTE_IS_DN}")
    login_module=$(add_option "$login_module" "roleNameAttributeID" "${AUTH_LDAP_ROLE_NAME_ATTRIBUTE_ID}")
    login_module=$(add_option "$login_module" "defaultRole" "${AUTH_LDAP_DEFAULT_ROLE}")
    login_module=$(add_option "$login_module" "roleRecursion" "${AUTH_LDAP_ROLE_RECURSION}")
    login_module=$(add_option "$login_module" "distinguishedNameAttribute" "${AUTH_LDAP_DISTINGUISHED_NAME_ATTRIBUTE}")
    login_module=$(add_option "$login_module" "parseRoleNameFromDN" "${AUTH_LDAP_PARSE_ROLE_NAME_FROM_DN}")
    login_module=$(add_option "$login_module" "parseUsername" "${AUTH_LDAP_PARSE_USERNAME}")
    login_module=$(add_option "$login_module" "usernameBeginString" "${AUTH_LDAP_USERNAME_BEGIN_STRING}")
    login_module=$(add_option "$login_module" "usernameEndString" "${AUTH_LDAP_USERNAME_END_STRING}")
    login_module=$(add_option "$login_module" "searchTimeLimit" "${AUTH_LDAP_SEARCH_TIME_LIMIT}")
    login_module=$(add_option "$login_module" "searchScope" "${AUTH_LDAP_SEARCH_SCOPE}")
    login_module=$(add_option "$login_module" "allowEmptyPasswords" "${AUTH_LDAP_ALLOW_EMPTY_PASSWORDS}")
    login_module=$(add_option "$login_module" "referralUserAttributeIDToCheck" "${AUTH_LDAP_REFERRAL_USER_ATTRIBUTE_ID_TO_CHECK}")
    add_login_module "${login_module}"
}

function configure_role_mapper_login_module() {
    if [[ -z ${AUTH_ROLE_MAPPER_ROLES_PROPERTIES} ]]; then
        log_info "AUTH_ROLE_MAPPER_ROLES_PROPERTIES not set. Skipping RoleMapping login module."
        return
    fi
    log_info "AUTH_ROLE_MAPPER_ROLES_PROPERTIES is set to ${AUTH_ROLE_MAPPER_ROLES_PROPERTIES}"
    local login_module=$(build_login_module "org.jboss.security.auth.spi.RoleMappingLoginModule" "optional")
    login_module=$(add_option "$login_module" "rolesProperties" ${AUTH_ROLE_MAPPER_ROLES_PROPERTIES})
    login_module=$(add_option "$login_module" "replaceRole" ${AUTH_ROLE_MAPPER_REPLACE_ROLE})
    add_login_module "${login_module}"
}

function configure_auth_login_modules() {
    configure_ldap_login_module
    configure_role_mapper_login_module
}