#!/bin/sh
# Openshift JBoss KIE - Smart Router launch script and helpers
set -e

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added
ROUTER_DIR=/opt/${JBOSS_PRODUCT}

# Add custom launch script and dependent scripts/libraries/snippets
cp -p ${ADDED_DIR}/openshift-launch.sh ${ROUTER_DIR}/
# Add logging configuration
cp -p ${ADDED_DIR}/configuration/logging.properties ${ROUTER_DIR}/

mkdir -p ${LAUNCH_DIR}
cp -r ${ADDED_DIR}/launch/* ${LAUNCH_DIR}

# Ensure that the local data directory exists
mkdir -p ${ROUTER_DIR}/data

# Necessary to permit running with a randomised UID
chown -R jboss:root ${ROUTER_DIR}
chmod -R 777 ${ROUTER_DIR}
