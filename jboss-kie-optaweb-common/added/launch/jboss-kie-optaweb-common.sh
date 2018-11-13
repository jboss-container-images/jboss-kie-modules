#!/bin/bash

source "${JBOSS_HOME}/bin/launch/launch-common.sh"
source "${JBOSS_HOME}/bin/launch/logging.sh"
source "${JBOSS_HOME}/bin/launch/jboss-kie-wildfly-security.sh"

#function prepareEnv() {
    # please keep these in alphabetical order
#}

function configureEnv() {
    configure
}

function configure() {
    configure_optaweb_security
    configure_optaweb_generator
    configure_property_replacement
}

function configure_optaweb_security() {
    # add eap users (see jboss-kie-wildfly-security.sh)
    add_kie_admin_user
}

function configure_optaweb_generator() {
    if [ "${OPTAWEB_GENERATOR_ZONE_ID}" != "" ]; then
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Doptaweb.generator.zoneId=${OPTAWEB_GENERATOR_ZONE_ID}"
    fi
}

function configure_property_replacement() {
    sed -i "s/<spec-descriptor-property-replacement>false/<spec-descriptor-property-replacement>true/g" $CONFIG_FILE
}
