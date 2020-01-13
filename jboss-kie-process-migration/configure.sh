#!/bin/sh
# Openshift JBoss KIE - Process migration launch script and helpers
set -e

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added
PROCESS_MIGRATION_DIR=/opt/${JBOSS_PRODUCT}
JDBC_DRIVERS=${PROCESS_MIGRATION_DIR}/drivers
SOURCES_DIR="/tmp/artifacts"

# Add custom launch script and dependent scripts/libraries/snippets
cp -p ${ADDED_DIR}/openshift-launch.sh ${PROCESS_MIGRATION_DIR}/

mkdir -p ${LAUNCH_DIR}
cp -r ${ADDED_DIR}/launch/* ${LAUNCH_DIR}

mkdir -p ${CONFIG_DIR}
cp -r ${ADDED_DIR}/configuration/* ${CONFIG_DIR}

mkdir -p ${JDBC_DRIVERS}
cp -p ${SOURCES_DIR}/postgresql*.jar ${JDBC_DRIVERS}
cp -p ${SOURCES_DIR}/mariadb*.jar ${JDBC_DRIVERS}
ln -s ${JDBC_DRIVERS}/postgresql*.jar ${JDBC_DRIVERS}/postgresql.jar
ln -s ${JDBC_DRIVERS}/mariadb-java-client*.jar ${JDBC_DRIVERS}/mariadb-java-client.jar

# Necessary to permit running with a randomised UID
chown -R jboss:root ${PROCESS_MIGRATION_DIR}
chmod -R 777 ${PROCESS_MIGRATION_DIR}
