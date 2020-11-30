#!/bin/sh
set -e

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added

cp -p ${ADDED_DIR}/launch/* $JBOSS_HOME/bin/launch/
