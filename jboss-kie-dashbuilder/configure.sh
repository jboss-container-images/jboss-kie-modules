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

mkdir -p /opt/kie/dashbuilder/{imports,components}
chown -R jboss:root /opt/kie

# Necessary to permit running with a randomised UID
for dir in $JBOSS_HOME/bin /opt/kie; do
    chown -R jboss:root $dir
    chmod -R g+rwX $dir
done