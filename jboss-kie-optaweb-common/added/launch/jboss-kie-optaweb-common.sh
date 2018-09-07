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
    configure_optaweb_generator
    configure_property_replacement
}

function configure_optaweb_generator() {
    if [ "${OPTAWEB_GENERATOR_ZONE_ID}" != "" ]; then
        JBOSS_KIE_ARGS="${JBOSS_KIE_ARGS} -Doptaweb.generator.zoneId=${OPTAWEB_GENERATOR_ZONE_ID}"
    fi
}

function configure_property_replacement() {
    sed -i.bak "s/<spec-descriptor-property-replacement>false/<spec-descriptor-property-replacement>true/g" $JBOSS_HOME/standalone/configuration/standalone-openshift.xml
}
