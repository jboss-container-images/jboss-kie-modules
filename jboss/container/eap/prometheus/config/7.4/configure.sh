#!/bin/sh
# Configure module
set -e

SCRIPT_DIR=$(dirname $0)
ARTIFACTS_DIR=${SCRIPT_DIR}/artifacts
SRC_DIR=${SCRIPT_DIR}/src

chown -R jboss:root ${ARTIFACTS_DIR}
chmod 775 ${ARTIFACTS_DIR}/opt/jboss/container/prometheus/etc/jmx-exporter-config.yaml

pushd ${ARTIFACTS_DIR}
cp -pr * /
popd

# Add prometheus configuration
cat ${SRC_DIR}/standalone.conf >> $JBOSS_HOME/bin/standalone.conf
