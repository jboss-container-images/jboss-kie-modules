#!/usr/bin/env bash

source "${JBOSS_HOME}/bin/launch/logging.sh"

function unset_kie_security_auth_env() {
    # please keep these in alphabetical order
    unset AUTH_LDAP_ALLOW_EMPTY_PASSWORDS
    unset AUTH_LDAP_BASE_CTX_DN
    unset AUTH_LDAP_BASE_FILTER
    unset AUTH_LDAP_BIND_CREDENTIAL
    unset AUTH_LDAP_BIND_DN
    unset AUTH_LDAP_DEFAULT_ROLE
    unset AUTH_LDAP_MAPPER_KEEP_MAPPED
    unset AUTH_LDAP_MAPPER_KEEP_NON_MAPPED
    unset AUTH_LDAP_NEW_IDENTITY_ATTRIBUTES
    unset AUTH_LDAP_RECURSIVE_SEARCH
    unset AUTH_LDAP_REFERRAL_MODE
    unset AUTH_LDAP_ROLE_ATTRIBUTE_ID
    unset AUTH_LDAP_ROLE_FILTER
    unset AUTH_LDAP_ROLE_RECURSION
    unset AUTH_LDAP_ROLES_CTX_DN
    unset AUTH_LDAP_SEARCH_TIME_LIMIT
    unset AUTH_LDAP_URL
    unset AUTH_ROLE_MAPPER_ROLES_PROPERTIES
}

function prepareEnv() {
    unset KIE_ELYTRON_FS_PATH
    unset KIE_GIT_CONFIG_PATH
    unset_kie_security_auth_env
}

function configureEnv() {
    configure
}

function configure() {
    configure_kie_fs_realm
    configure_business_central_kie_git_config
    configure_elytron_ldap_auth
    configure_elytron_http_auth_factory
    configure_ldap_sec_domain
    configure_new_identity_attributes
    configure_role_decoder
    update_activemq_domain
    update_jboss_web_xml
    update_security_domain
}

function configure_kie_fs_realm() {
    local path=$(get_kie_fs_path)
    local fs_realm="<filesystem-realm name=\"KieFsRealm\">\n\
                    <file path=\"${path}\"/>\
                </filesystem-realm>"

    sed -i "s|<!-- ##KIE_FS_REALM## -->|${fs_realm}|" $CONFIG_FILE
    if [ "${JBOSS_PRODUCT}" = "rhpam-kieserver" ]; then
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.kie.server.services.jbpm.security.filesystemrealm.folder-path=${path}"
    else
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.uberfire.ext.security.management.wildfly.filesystem.folder-path=${path}"
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.uberfire.ext.security.management.wildfly.cli.folderPath=${path}"
    fi
}

function configure_role_decoder() {
    local role_decoder="role"
    if [ "${AUTH_LDAP_URL}x" != "x" ]; then
        role_decoder="Roles"
    fi
    sed -i "s|<!-- ##KIE_ROLE_DECODER## -->|<simple-role-decoder name=\"from-roles-attribute\" attribute=\"${role_decoder}\"/>|" $CONFIG_FILE
}

function update_security_domain() {
   if [ "${SSO_URL}x" == "x" ]; then
       # undertow subsystem
        sed -i "s|<!-- ##HTTP_APPLICATION_SECURITY_DOMAIN## -->|<application-security-domain name=\"other\" security-domain=\"$(get_security_domain)\"/>\n\
                        <!-- ##HTTP_APPLICATION_SECURITY_DOMAIN## -->|" $CONFIG_FILE
   fi
   # ejb subsystem
   sed -i "s|<!-- ##EJB_APPLICATION_SECURITY_DOMAIN## -->|<application-security-domain name=\"other\" security-domain=\"$(get_security_domain)\"/>\n\
                   <!-- ##EJB_APPLICATION_SECURITY_DOMAIN## -->|" $CONFIG_FILE
}

function update_jboss_web_xml() {
    sed -i "s|<security-domain>other</security-domain>||" ${JBOSS_HOME}/standalone/deployments/ROOT.war/WEB-INF/jboss-web.xml
}

function update_activemq_domain() {
    sed -i "s|<server name=\"default\">|      <server name=\"default\">\n        <security elytron-domain=\"$(get_security_domain)\"/>|" $CONFIG_FILE
}

function get_kie_fs_path() {
    echo "${KIE_ELYTRON_FS_PATH:-/opt/kie/data/kie-fs-realm-users}"
}

function configure_business_central_kie_git_config() {
    if [ "${SSO_URL}x" != "x" ] && [[ "${JBOSS_PRODUCT}" =~ rhpam-businesscentral|rhdm-decisioncentral ]]; then
        if [ "${KIE_GIT_CONFIG_PATH}x" == "x" ]; then
            if [ "${SSO_PUBLIC_KEY}x" != "x" ]; then
                local public_key="\"realm-public-key\": \"${SSO_PUBLIC_KEY}\","
            fi

            cat <<EOF > "$JBOSS_HOME/kie_git_config.json"
{
    "realm": "${SSO_REALM}",
    ${public_key}
    "auth-server-url": "${SSO_URL}",
    "ssl-required": "external",
    "resource": "kie-git",
    "credentials": {
        "secret": "${SSO_SECRET}"
    }
}
EOF
            sed -i '/^[[:space:]]*$/d' "$JBOSS_HOME/kie_git_config.json"
        else
            if [ -f "${KIE_GIT_CONFIG_PATH}" ]; then
                 JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.uberfire.ext.security.keycloak.keycloak-config-file=${KIE_GIT_CONFIG_PATH}"
            else
                log_warning "The provided git configuration ${KIE_GIT_CONFIG_PATH} not found."
            fi
        fi
    fi
}

function get_security_domain() {
    local sec_domain="ApplicationDomain"
    if [ "${AUTH_LDAP_URL}x" != "x" ]; then
        sec_domain="KIELdapSecurityDomain"
    fi
    echo ${sec_domain}
}

function configure_elytron_ldap_auth() {
    if [[ -z ${AUTH_LDAP_URL} ]]; then
        log_info "AUTH_LDAP_URL not set. Skipping LDAP integration..."
        return
    fi
    log_info "AUTH_LDAP_URL is set to [${AUTH_LDAP_URL}], setting up LDAP authentication with elytron..."
    # configure dir-context, ldap url and bind credentials
    local read_timeout=""
    if [ "${AUTH_LDAP_SEARCH_TIME_LIMIT}x" != "x" ]; then
        read_timeout="read-timeout=\"${AUTH_LDAP_SEARCH_TIME_LIMIT}\" "
    fi

    local referral_mode=""
    local supported_referral_mode="FOLLOW IGNORE THROW"
    if [ "${AUTH_LDAP_REFERRAL_MODE}x" != "x" ]; then
         for referral in ${supported_referral_mode[@]}; do
            if [ "${referral}" = "${AUTH_LDAP_REFERRAL_MODE^^}" ]; then
                referral_mode="referral-mode=\"${referral}\""
            else
                log_warning "Provided referral mode [${AUTH_LDAP_REFERRAL_MODE}] is not valid, ignoring referral mode"
            fi
         done
    fi

    local kie_elytron_ldap_dir_context="\n            <dir-contexts>\n\
                <dir-context name=\"KIELdapDC\" url=\"${AUTH_LDAP_URL}\" ${read_timeout}${referral_mode}"
    if [[ ! -z ${AUTH_LDAP_BIND_DN} ]] && [[ ! -z ${AUTH_LDAP_BIND_CREDENTIAL} ]]; then
        kie_elytron_ldap_dir_context="${kie_elytron_ldap_dir_context} principal=\"${AUTH_LDAP_BIND_DN}\">\n\
                    <credential-reference clear-text=\"${AUTH_LDAP_BIND_CREDENTIAL}\"/>\n\
                </dir-context>\n\
            </dir-contexts>"
    else
         kie_elytron_ldap_dir_context="${kie_elytron_ldap_dir_context} />\n\
          </dir-contexts>"
    fi
    sed -i "s|<!-- ##KIE_LDAP_DIR_CONTEXT## -->|${kie_elytron_ldap_dir_context}|" $CONFIG_FILE


    # configure ldap-realm
    local allow_empty_pass=""
    if [ "${AUTH_LDAP_ALLOW_EMPTY_PASSWORDS^^}" == "TRUE" ]; then
        allow_empty_pass="direct-verification=\"true\" allow-blank-password=\"true\" "
    fi
    local kie_elytron_ldap_realm="<ldap-realm name=\"KIELdapRealm\" ${allow_empty_pass}dir-context=\"KIELdapDC\">\n\
                <identity-mapping rdn-identifier=\"${AUTH_LDAP_BASE_FILTER}\" search-base-dn=\"${AUTH_LDAP_BASE_CTX_DN}\""

    if [ "${AUTH_LDAP_RECURSIVE_SEARCH^^}" == "TRUE" ]; then
        kie_elytron_ldap_realm="${kie_elytron_ldap_realm} use-recursive-search=\"${AUTH_LDAP_RECURSIVE_SEARCH}\">\n"
    else
        kie_elytron_ldap_realm="${kie_elytron_ldap_realm}>\n"
    fi
    kie_elytron_ldap_realm="${kie_elytron_ldap_realm} \
                   <!-- ##KIE_LDAP_ATTRIBUTE_MAPPING## -->\n\
                    <!-- ##KIE_LDAP_NEW_IDENTITY_ATTRIBUTES## -->\n\
                    <user-password-mapper from=\"userPassword\" writable=\"true\"/>\n\
                </identity-mapping>\n\
            </ldap-realm>"
    sed -i "s|<!-- ##KIE_LDAP_REALM## -->|${kie_elytron_ldap_realm}|" $CONFIG_FILE

    # configure ldap attribute mapping
    local kie_elytron_ldap_attribute_mapping="<attribute-mapping>\n\
                        <attribute from=\"${AUTH_LDAP_ROLE_ATTRIBUTE_ID}\" \
                        to=\"Roles\" \
                        filter=\"${AUTH_LDAP_ROLE_FILTER}\" \
                        filter-base-dn=\"${AUTH_LDAP_ROLES_CTX_DN}\""
    if [ "${AUTH_LDAP_ROLE_RECURSION}x" != "x" ]; then
        kie_elytron_ldap_attribute_mapping="${kie_elytron_ldap_attribute_mapping} role-recursion=\"${AUTH_LDAP_ROLE_RECURSION}\"/>\n"
    else
        kie_elytron_ldap_attribute_mapping="${kie_elytron_ldap_attribute_mapping}/>\n"
    fi
    kie_elytron_ldap_attribute_mapping="${kie_elytron_ldap_attribute_mapping}                    </attribute-mapping>"
    sed -i "s|<!-- ##KIE_LDAP_ATTRIBUTE_MAPPING## -->|${kie_elytron_ldap_attribute_mapping}|" $CONFIG_FILE

}

function configure_ldap_sec_domain() {
    if [ "${AUTH_LDAP_URL}x" != "x" ]; then
        local sec_domain_default_role=""
        if [ "${AUTH_LDAP_DEFAULT_ROLE}x" != "x" ]; then
            sec_domain_default_role="role-mapper=\"kie-ldap-role-mapper\" "
            local default_role="<constant-role-mapper name=\"kie-ldap-role-mapper\">\n\
                    <role name=\"${AUTH_LDAP_DEFAULT_ROLE}\"/>\n\
                </constant-role-mapper>"
            sed -i "s|<!-- ##KIE_AUTH_LDAP_DEFAULT_ROLE## -->|${default_role}|" $CONFIG_FILE
        fi

        local sec_domain="<security-domain name=\"KIELdapSecurityDomain\" default-realm=\"KIELdapRealm\" ${sec_domain_default_role}permission-mapper=\"default-permission-mapper\">\n\
                    <realm name=\"KIELdapRealm\" role-decoder=\"from-roles-attribute\"/>\n\
                </security-domain>"
        sed -i "s|<!-- ##KIE_LDAP_SECURITY_DOMAIN## -->|${sec_domain}|" $CONFIG_FILE
    fi
}

function configure_elytron_http_auth_factory() {
    if [ "${AUTH_LDAP_URL}x" != "x" ]; then
        local http_authentication_factory="<http-authentication-factory name=\"kie-ldap-http-auth\" http-server-mechanism-factory=\"global\" security-domain=\"KIELdapSecurityDomain\">\n\
                    <mechanism-configuration>\n\
                        <mechanism mechanism-name=\"BASIC\">\n\
                            <mechanism-realm realm-name=\"KIELdapRealm\"/>\n\
                        </mechanism>\n\
                        <mechanism mechanism-name=\"FORM\"/>\n\
                    </mechanism-configuration>\n\
                </http-authentication-factory>"
        sed -i "s|<!-- ##HTTP_AUTHENTICATION_FACTORY## -->|${http_authentication_factory}<!-- ##HTTP_AUTHENTICATION_FACTORY## -->|" $CONFIG_FILE
    fi

}

function elytron_role_mapping() {
    local mapped_roles
    if [ -f "${AUTH_ROLE_MAPPER_ROLES_PROPERTIES}" ]; then
        while IFS= read -r line
        do
            [[ "${line}" = \#* ]] && continue
            role=$(echo $line | cut -d= -f1)
            map_to=$(echo $line | cut -d= -f2 | sed 's/,/ /g')
            mapped_roles="${mapped_roles}<role-mapping from=\"${role}\" to=\"${map_to}\"/>\r"
        done < "$AUTH_ROLE_MAPPER_ROLES_PROPERTIES"
    else
        IFS=";" read -a roles_to_map <<< $AUTH_ROLE_MAPPER_ROLES_PROPERTIES
        for role_to_map in ${roles_to_map[@]}; do
        	if [[ $role_to_map =~ [0-9a-zA-Z]=[0-9a-zA-Z] ]];then
        		role=$(echo $role_to_map | cut -d= -f1)
			    map_to=$(echo $role_to_map | cut -d= -f2 | sed 's/,/ /g')
        		mapped_roles="${mapped_roles}<role-mapping from=\"${role}\" to=\"${map_to}\"/>\r"
        	else
        		log_warning "$role_to_map is a not valid role to map, should be string=string1,string2"
        	fi
        done
    fi
    local role_mapper="<mapped-role-mapper name=\"kie-custom-role-mapper\" keep-mapped=\"${AUTH_LDAP_MAPPER_KEEP_MAPPED:-false}\" keep-non-mapped=\"${AUTH_LDAP_MAPPER_KEEP_NON_MAPPED:-false}\">\n\
                   $(echo -ne ${mapped_roles} | sed '/^[[:space:]]*$/d')\n\
                </mapped-role-mapper>"
     sed -i "s|<!-- ##AUTH_ROLE_MAPPER## -->|${role_mapper}|" $CONFIG_FILE
}

function configure_new_identity_attributes() {
    if [ ! -z "${AUTH_LDAP_NEW_IDENTITY_ATTRIBUTES}" ]; then
        local new_identities="<new-identity-attributes>\n                        <!-- ##IDENTITY## -->\n                    </new-identity-attributes>"
        local identity
        IFS=";" read -a attributes <<< ${AUTH_LDAP_NEW_IDENTITY_ATTRIBUTES}
        for attribute in "${attributes[@]}"; do
            name=$(echo $attribute | cut -d= -f1)
            value=$(echo $attribute | cut -d= -f2 | sed 's/,/ /g')
            identity="${identity}<attribute name=\"${name}\" value=\"${value}\"/>\r"
        done
    fi
    sed -i "s|<!-- ##KIE_LDAP_NEW_IDENTITY_ATTRIBUTES## -->|${new_identities}|" $CONFIG_FILE
    sed -i "s|<!-- ##IDENTITY## -->|${identity}|" $CONFIG_FILE
}


