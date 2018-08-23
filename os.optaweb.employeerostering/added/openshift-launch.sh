#!/bin/sh
# Openshift RHDM Employee Rostering Optimizer launch script

source $JBOSS_HOME/bin/launch/logging.sh

if [ "${SCRIPT_DEBUG}" = "true" ] ; then
    set -x
    log_info "Script debugging is enabled, allowing bash commands and their arguments to be printed as they are executed"
fi

CONFIG_FILE=$JBOSS_HOME/standalone/configuration/standalone-openshift.xml
LOGGING_FILE=$JBOSS_HOME/standalone/configuration/logging.properties

CONFIGURE_SCRIPTS=(
  $JBOSS_HOME/bin/launch/backward-compatibility.sh
  $JBOSS_HOME/bin/launch/configure_extensions.sh
  $JBOSS_HOME/bin/launch/passwd.sh
  $JBOSS_HOME/bin/launch/messaging.sh
  $JBOSS_HOME/bin/launch/datasource.sh
  $JBOSS_HOME/bin/launch/resource-adapter.sh
  $JBOSS_HOME/bin/launch/admin.sh
  $JBOSS_HOME/bin/launch/ha.sh
  $JBOSS_HOME/bin/launch/jgroups.sh
  $JBOSS_HOME/bin/launch/https.sh
  $JBOSS_HOME/bin/launch/json_logging.sh
  $JBOSS_HOME/bin/launch/security-domains.sh
  $JBOSS_HOME/bin/launch/jboss_modules_system_pkgs.sh
  $JBOSS_HOME/bin/launch/keycloak.sh
  $JBOSS_HOME/bin/launch/deploymentScanner.sh
  $JBOSS_HOME/bin/launch/ports.sh
  $JBOSS_HOME/bin/launch/maven-repos.sh
  $JBOSS_HOME/bin/launch/access_log_valve.sh
  /opt/run-java/proxy-options
)

source $JBOSS_HOME/bin/launch/configure.sh

log_info "Running $JBOSS_IMAGE_NAME image, version $JBOSS_IMAGE_VERSION"

if [ -n "$CLI_GRACEFUL_SHUTDOWN" ] ; then
  trap "" TERM
  log_info "Using CLI Graceful Shutdown instead of TERM signal"
fi

#for persistence.xml, in order to use external DB instead of the hard-coded default H2 db. 
JBOSS_BPMSUITE_ARGS="${JBOSS_BPMSUITE_ARGS} -Dorg.optaweb.employeerostering.persistence.datasource=${OPTAWEB_ROSTERING_PERSISTENCE_DATASOURCE} -Dorg.optaweb.employeerostering.persistence.dialect=${OPTAWEB_ROSTERING_PERSISTENCE_DIALECT}"
sed  -i.bak "s/<spec-descriptor-property-replacement>false/<spec-descriptor-property-replacement>true/g" $JBOSS_HOME/standalone/configuration/standalone-openshift.xml

exec env M2_HOME=${M2_HOME} $JBOSS_HOME/bin/standalone.sh -c standalone-openshift.xml -bmanagement 127.0.0.1 ${JAVA_PROXY_OPTIONS} ${JBOSS_HA_ARGS} ${JBOSS_MESSAGING_ARGS} ${JBOSS_BPMSUITE_ARGS}
