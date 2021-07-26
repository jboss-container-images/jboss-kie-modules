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

# /opt/kie directory
KIE_HOME_DIR=/opt/kie
mkdir -p ${KIE_HOME_DIR}

# Necessary to permit running with a randomised UID
for dir in $JBOSS_HOME/bin $HOME $KIE_HOME_DIR; do
    chown -R jboss:root $dir
    chmod -R g+rwX $dir
done

