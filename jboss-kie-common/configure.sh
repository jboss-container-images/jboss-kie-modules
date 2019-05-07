#!/bin/bash
# Move the parent EAP readiness and liveness probe scripts and install child versions
set -e

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added

# Necessary to permit running with a randomised UID
chown -R jboss:root $SCRIPT_DIR
chmod -R g+rwX $SCRIPT_DIR

cp -p "$ADDED_DIR/jboss-kie-common.sh" $JBOSS_HOME/bin/

chmod ug+x $JBOSS_HOME/bin/jboss-kie-common.sh
