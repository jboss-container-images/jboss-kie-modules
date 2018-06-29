#!/bin/bash

########## Environment Variables ##########

function unset_kie_security_ldap_env() {
    # please keep these in alphabetical order
    unset KIE_AUTH_LDAP_ALLOW_EMPTY_PASSWORDS
    unset KIE_AUTH_LDAP_BASE_CTX_DN
    unset KIE_AUTH_LDAP_BASE_FILTER
    unset KIE_AUTH_LDAP_BIND_CREDENTIAL
    unset KIE_AUTH_LDAP_BIND_DN
    unset KIE_AUTH_LDAP_DEFAULT_ROLE
    unset KIE_AUTH_LDAP_DISTINGUISHED_NAME_ATTRIBUTE
    unset KIE_AUTH_LDAP_JAAS_SECURITY_DOMAIN
    unset KIE_AUTH_LDAP_PARSE_ROLE_NAME_FROM_DN
    unset KIE_AUTH_LDAP_PARSE_USERNAME
    unset KIE_AUTH_LDAP_REFERRAL_USER_ATTRIBUTE_ID_TO_CHECK
    unset KIE_AUTH_LDAP_ROLE_ATTRIBUTE_ID
    unset KIE_AUTH_LDAP_ROLE_ATTRIBUTE_IS_DN
    unset KIE_AUTH_LDAP_ROLE_FILTER
    unset KIE_AUTH_LDAP_ROLE_NAME_ATTRIBUTE_ID
    unset KIE_AUTH_LDAP_ROLE_RECURSION
    unset KIE_AUTH_LDAP_ROLES_CTX_DN
    unset KIE_AUTH_LDAP_SEARCH_SCOPE
    unset KIE_AUTH_LDAP_SEARCH_TIME_LIMIT
    unset KIE_AUTH_LDAP_URL
    unset KIE_AUTH_LDAP_USERNAME_BEGIN_STRING
    unset KIE_AUTH_LDAP_USERNAME_END_STRING
}

function add_module() {
    local xml=$1
    local name=$2
    local envVar=$3

    if [[ ! -z ${envVar} ]]; then
        echo ${xml} '<module-option name="'${name}'" value="'${envVar}'"/>'
    else
        echo ${xml}
    fi
}

function configure_ldap_security_domain() {
    if [[ -z ${KIE_AUTH_LDAP_URL} ]]; then
        log_info "KIE_AUTH_LDAP_URL not set. Skipping LDAP integration..."
        return
    fi
    log_info "KIE_AUTH_LDAP_URL is set to ${KIE_AUTH_LDAP_URL}. Added LdapExtended login-module"
    local security_domain='<login-module code="LdapExtended" flag="required">'

    security_domain=$(add_module "$security_domain" "java.naming.provider.url" "${KIE_AUTH_LDAP_URL}") 
    security_domain=$(add_module "$security_domain" "jaasSecurityDomain" "${KIE_AUTH_LDAP_JAAS_SECURITY_DOMAIN}") 
    security_domain=$(add_module "$security_domain" "bindDN" "${KIE_AUTH_LDAP_BIND_DN}") 
    security_domain=$(add_module "$security_domain" "bindCredential" "${KIE_AUTH_LDAP_BIND_CREDENTIAL}") 
    security_domain=$(add_module "$security_domain" "baseCtxDN" "${KIE_AUTH_LDAP_BASE_CTX_DN}") 
    security_domain=$(add_module "$security_domain" "baseFilter" "${KIE_AUTH_LDAP_BASE_FILTER}")
    security_domain=$(add_module "$security_domain" "rolesCtxDN" "${KIE_AUTH_LDAP_ROLES_CTX_DN}") 
    security_domain=$(add_module "$security_domain" "roleFilter" "${KIE_AUTH_LDAP_ROLE_FILTER}")
    security_domain=$(add_module "$security_domain" "roleAttributeID" "${KIE_AUTH_LDAP_ROLE_ATTRIBUTE_ID}")
    security_domain=$(add_module "$security_domain" "roleAttributeIsDN" "${KIE_AUTH_LDAP_ROLE_ATTRIBUTE_IS_DN}")
    security_domain=$(add_module "$security_domain" "roleNameAttributeID" "${KIE_AUTH_LDAP_ROLE_NAME_ATTRIBUTE_ID}")
    security_domain=$(add_module "$security_domain" "defaultRole" "${KIE_AUTH_LDAP_DEFAULT_ROLE}")
    security_domain=$(add_module "$security_domain" "roleRecursion" "${KIE_AUTH_LDAP_ROLE_RECURSION}")
    security_domain=$(add_module "$security_domain" "distinguishedNameAttribute" "${KIE_AUTH_LDAP_DISTINGUISHED_NAME_ATTRIBUTE}")
    security_domain=$(add_module "$security_domain" "parseRoleNameFromDN" "${KIE_AUTH_LDAP_PARSE_ROLE_NAME_FROM_DN}")
    security_domain=$(add_module "$security_domain" "parseUsername" "${KIE_AUTH_LDAP_PARSE_USERNAME}")
    security_domain=$(add_module "$security_domain" "usernameBeginString" "${KIE_AUTH_LDAP_USERNAME_BEGIN_STRING}")
    security_domain=$(add_module "$security_domain" "usernameEndString" "${KIE_AUTH_LDAP_USERNAME_END_STRING}")
    security_domain=$(add_module "$security_domain" "searchTimeLimit" "${KIE_AUTH_LDAP_SEARCH_TIME_LIMIT}")
    security_domain=$(add_module "$security_domain" "searchScope" "${KIE_AUTH_LDAP_SEARCH_SCOPE}")
    security_domain=$(add_module "$security_domain" "allowEmptyPasswords" "${KIE_AUTH_LDAP_ALLOW_EMPTY_PASSWORDS}")
    security_domain=$(add_module "$security_domain" "referralUserAttributeIDToCheck" "${KIE_AUTH_LDAP_REFERRAL_USER_ATTRIBUTE_ID_TO_CHECK}") 
    
    security_domain="${security_domain}"'</login-module><!-- ##OTHER_LOGIN_MODULES## -->'

    sed -i "s|<!-- ##OTHER_LOGIN_MODULES## -->|${security_domain}|" "${CONFIG_FILE}"
}
