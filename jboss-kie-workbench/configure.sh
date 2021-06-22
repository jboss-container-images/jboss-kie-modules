#!/bin/sh
# Openshift JBoss KIE - Workbench launch script and helpers
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

# Ensure that the local data directory exists
DATA_DIR=${JBOSS_HOME}/standalone/data
KIE_HOME_DIR=/opt/kie
mkdir -p ${DATA_DIR}
mkdir -p ${KIE_HOME_DIR}
# Necessary to permit running with a randomised UID
chown -R jboss:root ${DATA_DIR}
chmod -R 777 ${DATA_DIR}
chown -R jboss:root ${KIE_HOME_DIR}
chmod -R 777 ${KIE_HOME_DIR}

# Create dir to remove JDBC driver
mkdir ${JBOSS_HOME}/modules/system/layers/openshift 2&> /dev/null || true
chown -R jboss:root ${JBOSS_HOME}/modules/system/layers/openshift