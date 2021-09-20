#!/usr/bin/env bash

source "${LAUNCH_DIR}/logging.sh"
source "${LAUNCH_DIR}/launch-common.sh"
source "${LAUNCH_DIR}/jboss-kie-pim-common.sh"

function prepareEnv() {
    # please keep these in alphabetical order
    JBOSS_KIE_ADMIN_USER
    JBOSS_KIE_ADMIN_PWD
    JBOSS_KIE_EXTRA_CLASSPATH
}

function configureEnv() {
    configure
}

function configure() {
    configure_extra_classpath
    configure_admin_user
}

# Comma separated list of libraries to add to the classpath
function configure_extra_classpath() {
    local classpath
    if [[ -n ${JBOSS_KIE_EXTRA_CLASSPATH} ]]; then
        log_info "Copying extra libraries to $JBOSS_HOME/quarkus-app/lib/deployment"
        IFS=',' read -ra entries <<< "${JBOSS_KIE_EXTRA_CLASSPATH}"
        for entry in "${entries[@]}"; do
            echo ${entry}
            # extra libs needs to be augmented
            cp -v ${entry} $JBOSS_HOME/quarkus-app/lib/deployment
        done
    fi
}

function configure_admin_user() {
    # if user and pwd are not provided, and any yaml file is provided, don't create the user.
    if [ -f ${CONFIG_DIR}/application.yaml ]; then
        log_info "External configuration provided, no users will be created, be sure to configure the security properly."
    else
        if [ "${JBOSS_KIE_ADMIN_USER}x" != "x" ] &&  [ "${JBOSS_KIE_ADMIN_PWD}x" != "x" ]; then
            echo "${JBOSS_KIE_ADMIN_USER}=${JBOSS_KIE_ADMIN_PWD}" > ${CONFIG_DIR}/application-users.properties
            echo "${JBOSS_KIE_ADMIN_USER}=admin" > ${CONFIG_DIR}/application-roles.properties
            mv -v ${CONFIG_DIR}/default-auth.yaml ${CONFIG_DIR}/application.yaml
            log_info "Basic security auth added for user ${JBOSS_KIE_ADMIN_USER}, it is strongly recommended to provide your own configuration file using md5 hash to hide the password."
        else
            log_warning "No external configuration or user added, please set one of them."
        fi
    fi
}

