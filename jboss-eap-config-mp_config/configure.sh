#!/bin/sh
set -e

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added

. $JBOSS_HOME/bin/launch/files.sh

mkdir -p ${JBOSS_HOME}/bin/launch/

cp -p ${ADDED_DIR}/launch/mp-config.sh ${JBOSS_HOME}/bin/launch/
chmod ug+x ${JBOSS_HOME}/bin/launch/mp-config.sh

