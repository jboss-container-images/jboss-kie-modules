#!/bin/sh
# Openshift JBoss KIE - Controller launch script and helpers
set -e

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added

# Add custom launch script and dependent scripts/libraries/snippets
cp -p ${ADDED_DIR}/openshift-launch.sh ${JBOSS_HOME}/bin/
mkdir -p ${JBOSS_HOME}/bin/launch
cp -r ${ADDED_DIR}/launch/* ${JBOSS_HOME}/bin/launch
chmod ug+x ${JBOSS_HOME}/bin/openshift-launch.sh

# Set bin permissions
chown -R jboss:root ${JBOSS_HOME}/bin/
chmod -R g+rwX ${JBOSS_HOME}/bin/

# Create dir to remove JDBC driver
mkdir ${JBOSS_HOME}/modules/system/layers/openshift 2&> /dev/null || true
chown -R jboss:root ${JBOSS_HOME}/modules/system/layers/openshift
