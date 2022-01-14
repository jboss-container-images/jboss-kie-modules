#!/bin/sh
# Openshift JBoss KIE - Common scripts and helpers
set -e

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added

# Add common scripts/libraries/snippets
mkdir -p ${JBOSS_HOME}/bin/launch
cp -r ${ADDED_DIR}/launch/* ${JBOSS_HOME}/bin/launch

# Set bin permissions
chown -R jboss:root ${JBOSS_HOME}/bin/
chmod -R g+rwX ${JBOSS_HOME}/bin/

# Ensure that the local Maven repository exists
MVN_DIR=${HOME}/.m2
mkdir -p ${MVN_DIR}/repository
# Necessary to permit running with a randomised UID
chown -R jboss:root ${MVN_DIR}
chmod -R 777 ${MVN_DIR}

# Due to this issue https://github.com/cekit/cekit/issues/593
# to reduce docker layers in the build phase cleanup is performed
# here and not in a dedicated module

# Deleting folders domain, migration and installation
rm -rf ${JBOSS_HOME}/{domain,migration,.installation/*}

# Deleting all *.bat and *.ps1 and init.d folder
rm -rf ${JBOSS_HOME}/bin/{*.bat,*.ps1,init.d,domain*}

# Deleting not needed standalone-*.xml files
# NOTE: standalone.xml is referenced in the welcome-content
rm -rf ${JBOSS_HOME}/standalone/configuration/standalone-{full,ha,full-ha,load-balancer}.xml

# Deleting mgmt-groups and mgmt-users properties files
rm -rf ${JBOSS_HOME}/standalone/configuration/mgmt-*.properties