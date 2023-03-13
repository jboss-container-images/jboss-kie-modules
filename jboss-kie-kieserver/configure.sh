#!/bin/sh
# Openshift JBoss KIE - KIE Server launch script and helpers
set -e

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added
SOURCES_DIR="/tmp/artifacts"
KIE_SERVER_WAR_LOCATION="${JBOSS_HOME}/standalone/deployments/ROOT.war"

# Override the ejb-jar.xml file
rm -rf ${KIE_SERVER_WAR_LOCATION}/WEB-INF/weblogic-ejb-jar.xml
cp -v ${ADDED_DIR}/WEB-INF/ejb-jar.xml ${KIE_SERVER_WAR_LOCATION}/WEB-INF/

# Make sure the owner of added files is the 'jboss' user
chown -R jboss:jboss ${SCRIPT_DIR}

# Move the parent EAP S2I assemble script and install child S2I scripts
mv /usr/local/s2i/assemble /usr/local/s2i/assemble_eap
cp -r ${ADDED_DIR}/s2i/* /usr/local/s2i/
# Necessary to permit running with a randomised UID
chown -R jboss:root /usr/local/s2i
for F in $(ls /usr/local/s2i/*); do
    # Protect against "chmod: cannot operate on dangling symlink '/usr/local/s2i/scl-enable-maven'"
    if [ ! -L ${F} ]; then
        chmod ug+x ${F}
    fi
done

# Add custom launch script and dependent scripts/libraries/snippets
cp -p ${ADDED_DIR}/openshift-launch.sh ${JBOSS_HOME}/bin/
mkdir -p ${JBOSS_HOME}/bin/launch
cp -r ${ADDED_DIR}/launch/* ${JBOSS_HOME}/bin/launch
chmod ug+x ${JBOSS_HOME}/bin/openshift-launch.sh

# Set bin permissions
chown -R jboss:root ${JBOSS_HOME}/bin/
chmod -R g+rwX ${JBOSS_HOME}/bin/

# Set exec permissions for scripts files in the launch dir
chmod -R ug+x ${JBOSS_HOME}/bin/launch/*.sh

# Ensure that the local KIE maven repository exists
KIE_DIR=${HOME}/.kie
mkdir -p ${KIE_DIR}/repository
# Necessary to permit running with a randomised UID
chown -R jboss:root ${KIE_DIR}
chmod -R 755 ${KIE_DIR}

# /opt/kie directory
KIE_HOME_DIR=/opt/kie
mkdir -p ${KIE_HOME_DIR}
# kie-fs-realm
mkdir ${KIE_HOME_DIR}/data

# Necessary to permit running with a randomised UID
for dir in $JBOSS_HOME/bin $HOME $KIE_HOME_DIR; do
    chown -R jboss:root $dir
    chmod -R g+rwX $dir
done

# Create dir to remove JDBC driver
mkdir ${JBOSS_HOME}/modules/system/layers/openshift &> /dev/null || true
chown -R jboss:root ${JBOSS_HOME}/modules/system/layers/openshift

# Enable the jboss-eap-repository maven profile by default.
# There is a activation property for command line mvn commands (-Dcom.redhat.xpaas.repo.redhatga)
# however it seems not to apply to the kiesoup-maven integration for embedded integration, thus enable by default.
sed -i 's|<!-- ### active profiles ### -->|<activeProfile>jboss-eap-repository</activeProfile>\n\    <!-- ### active profiles ### -->|' ${HOME}/.m2/settings.xml