#!/bin/sh
# Openshift JBoss KIE - Process migration launch script and helpers
set -e

SCRIPT_DIR=$(dirname "$0")
ADDED_DIR=${SCRIPT_DIR}/added
PROCESS_MIGRATION_DIR=/opt/${JBOSS_PRODUCT}
JDBC_DRIVERS=${PROCESS_MIGRATION_DIR}/drivers

# Add custom launch script and dependent scripts/libraries/snippets
cp -p "${ADDED_DIR}"/openshift-launch.sh "${PROCESS_MIGRATION_DIR}"/

mkdir -p "${LAUNCH_DIR}"
cp -r "${ADDED_DIR}"/launch/* "${LAUNCH_DIR}"

mkdir -p "${CONFIG_DIR}"
cp -r "${ADDED_DIR}"/configuration/* "${CONFIG_DIR}"

mkdir -p "${JDBC_DRIVERS}"
link /usr/lib/java/mariadb-java-client.jar "${JDBC_DRIVERS}"/mariadb-java-client.jar
link /usr/share/java/postgresql-jdbc/postgresql.jar "${JDBC_DRIVERS}"/postgresql-jdbc.jar

# Necessary to permit running with a randomised UID
chown -R jboss:root "${PROCESS_MIGRATION_DIR}"
chmod -R 777 "${PROCESS_MIGRATION_DIR}"
