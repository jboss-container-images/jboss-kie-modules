#!/bin/bash

source "${JBOSS_HOME}/bin/launch/launch-common.sh"
source "${JBOSS_HOME}/bin/launch/logging.sh"
source "${JBOSS_HOME}/bin/launch/bpmsuite-security.sh"

function prepareEnv() {
    # please keep these in alphabetical order
    unset_kie_security_env
}

function configureEnv() {
    configure
}

function configure() {
    configure_controller_security
    configure_server_access
}

function configure_controller_security() {
    # add eap user (see bpmsuite-security.sh)
    add_kie_server_controller_user
}

function configure_server_access() {
    # user/pwd
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.user=\"$(get_kie_server_user)\""
    JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.pwd=\"$(esc_kie_server_pwd)\""
    # token
    local kieServerToken="$(get_kie_server_token)"
    if [ "${kieServerToken}" != "" ]; then
        JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.kie.server.token=\"${kieServerToken}\""
    fi
}
