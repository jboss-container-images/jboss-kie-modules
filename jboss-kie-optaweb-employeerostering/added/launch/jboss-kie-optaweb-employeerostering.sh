#!/bin/bash

source "${JBOSS_HOME}/bin/launch/launch-common.sh"
source "${JBOSS_HOME}/bin/launch/logging.sh"

#function prepareEnv() {
    # please keep these in alphabetical order
#}

function configureEnv() {
    configure
}

function configure() {
    configure_optaweb_employeerostering_persistence
}

function configure_optaweb_employeerostering_persistence() {
    # for persistence.xml property replacement
    if [ "${OPTAWEB_PERSISTENCE_DIALECT}" != "" ]; then
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.optaweb.employeerostering.persistence.dialect=${OPTAWEB_PERSISTENCE_DIALECT}"
    fi
    if [ "${OPTAWEB_PERSISTENCE_DS}" != "" ]; then
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Dorg.optaweb.employeerostering.persistence.datasource=${OPTAWEB_PERSISTENCE_DS}"
    fi
}
