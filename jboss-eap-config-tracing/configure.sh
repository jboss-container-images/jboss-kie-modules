#!/bin/sh
set -e

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added

. $JBOSS_HOME/bin/launch/files.sh

cp -p ${ADDED_DIR}/launch/tracing.sh ${JBOSS_HOME}/bin/launch/
chmod ug+x ${JBOSS_HOME}/bin/launch/tracing.sh


