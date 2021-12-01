#!/usr/bin/env bash

source "${JBOSS_HOME}/bin/launch/logging.sh"

function prepareEnv() {
    unset KIE_ELYTRON_FS_PATH
    unset KIE_GIT_CONFIG_PATH
}

function configureEnv() {
    configure
}

function configure() {
    configure_business_central_kie_git_config
    configure_kie_fs_realm
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

function update_security_domain() {
   if [ "${SSO_URL}x" == "x" ]; then
       # undertow subsystem
       sed -i "s|<!-- ##HTTP_APPLICATION_SECURITY_DOMAIN## -->|<application-security-domain name=\"other\" security-domain=\"ApplicationDomain\"/>\n\
                       <!-- ##HTTP_APPLICATION_SECURITY_DOMAIN## -->|" $CONFIG_FILE
   fi
}

function update_jboss_web_xml() {
    sed -i "s|<security-domain>other</security-domain>||" ${JBOSS_HOME}/standalone/deployments/ROOT.war/WEB-INF/jboss-web.xml
}

function update_activemq_domain() {
    sed -i "s|<server name=\"default\">|      <server name=\"default\">\n        <security elytron-domain=\"ApplicationDomain\"/>|" $CONFIG_FILE
}

function get_kie_fs_path() {
    echo "${KIE_ELYTRON_FS_PATH:-/opt/kie/data/kie-fs-realm-users}"
}

# TODO add the envs and KIE_GIT_CONFIG_PATH to BC/DC image.yaml
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