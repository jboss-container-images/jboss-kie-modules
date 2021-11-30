#!/usr/bin/env bash

source "${JBOSS_HOME}/bin/launch/logging.sh"

function prepareEnv() {
    unset KIE_ELYTRON_FS_PATH
}

function configureEnv() {
    configure
}

function configure() {
    configure_kie_fs_realm
    update_activemq_domain
    update_security_domain
}

function configure_kie_fs_realm() {
    if [ "${AUTH_LDAP_URL}x" == "x" ] && [ "${SSO_URL}x" == "x" ]; then
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
    fi
}

function update_security_domain() {
    sed -i "s|<security-domain>other</security-domain>||" ${JBOSS_HOME}/standalone/deployments/ROOT.war/WEB-INF/jboss-web.xml
    # undertow subsystem
    sed -i "s|<!-- ##HTTP_APPLICATION_SECURITY_DOMAIN## -->|<application-security-domain name="other" security-domain=\"$(get_application_domain)\"/>\n\
                    <!-- ##HTTP_APPLICATION_SECURITY_DOMAIN## -->|" $CONFIG_FILE
    # ejb subsystem
    sed -i "s|<!-- ##EJB_APPLICATION_SECURITY_DOMAIN## -->|<application-security-domain name="other" security-domain=\"$(get_application_domain)\"/>\n\
                    <!-- ##EJB_APPLICATION_SECURITY_DOMAIN## -->|" $CONFIG_FILE
}

function update_activemq_domain() {
    sed -i "s|<server name=\"default\">|      <server name=\"default\">\n        <security elytron-domain=\"$(get_application_domain)\"/>|" $CONFIG_FILE
}

function get_kie_fs_path() {
    echo "${KIE_ELYTRON_FS_PATH:-/opt/kie/data/kie-fs-realm-users}"
}


function get_application_domain() {
    if [ "${SSO_URL}x" != "x" ]; then
        echo "KeycloakDomain"
    else
        echo "ApplicationDomain"
    fi
}
