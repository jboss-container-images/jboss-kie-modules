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
    # TODO add behave test
    sed -i "s|<security-domain>other</security-domain>||" ${JBOSS_HOME}/standalone/deployments/ROOT.war/WEB-INF/jboss-web.xml
}

function update_activemq_domain() {
    # TODO add behave test
    sed -i "s|<server name=\"default\">|      <server name=\"default\">\n        <security elytron-domain=\"ApplicationDomain\"/>|" $CONFIG_FILE
}

function get_kie_fs_path() {
    echo "${KIE_ELYTRON_FS_PATH:-/opt/kie/data/kie-fs-realm-users}"
}

