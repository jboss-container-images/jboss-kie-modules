#!/bin/bash

source "${LAUNCH_DIR}/launch-common.sh"
source "${LAUNCH_DIR}/logging.sh"

function prepareEnv() {
    # please keep these in alphabetical order
    JBOSS_KIE_ADMIN_USER
    JBOSS_KIE_ADMIN_PWD
    JBOSS_KIE_EXTRA_CLASSPATH
    JBOSS_KIE_EXTRA_CONFIG
}

function configureEnv() {
    configure
}

function configure() {
    configure_extra_classpath
    configure_extra_config
    configure_users
}

function trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var##*( )}"
    # remove trailing whitespace characters
    var="${var%%*( )}"
    echo -n "$var"
}

# Comma separated list of libraries to add to the classpath
function configure_extra_classpath() {
    local classpath
    if [[ -n ${JBOSS_KIE_EXTRA_CLASSPATH} ]]; then
        IFS=',' read -ra entries <<< "${JBOSS_KIE_EXTRA_CLASSPATH}"
        for entry in "${entries[@]}"
        do
            if [[ -z ${classpath} ]]; then
                classpath="-Dthorntail.classpath=$(trim "${entry}")"
            else
                classpath="${classpath} -Dthorntail.classpath=$(trim "${entry}")"
            fi
        done
    fi
    JBOSS_KIE_EXTRA_CLASSPATH=${classpath}
}

function configure_extra_config() {
    if [[ -n ${JBOSS_KIE_EXTRA_CONFIG} ]]; then
        JBOSS_KIE_EXTRA_CONFIG="-s${JBOSS_KIE_EXTRA_CONFIG}"
    else
        JBOSS_KIE_EXTRA_CONFIG=""
    fi
}

function configure_users() {
    local user=${JBOSS_KIE_ADMIN_USER:-admin}
    local pwd=${JBOSS_KIE_ADMIN_PWD:-$(< /dev/urandom tr -dc A-Za-z0-9\!_ | head -c8)}
    sed -i -e "s;%USER%;$user;g" -e "s;%PASSWORD%;$pwd;g" "${CONFIG_DIR}"/application-users.properties
    sed -i -e "s;%USER%;$user;g" "${CONFIG_DIR}"/application-roles.properties
}
