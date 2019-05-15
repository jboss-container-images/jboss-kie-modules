#!/bin/sh
# Openshift JBoss KIE - Common scripts and helpers
set -e

 SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added

 # Add common scripts/libraries/snippets
mkdir -p ${JBOSS_HOME}/bin/launch
cp -r ${ADDED_DIR}/launch/* ${JBOSS_HOME}/bin/launch

 # Set bin permissions
chown -R jboss:root ${JBOSS_HOME}/bin/
chmod -R g+rwX ${JBOSS_HOME}/bin/
