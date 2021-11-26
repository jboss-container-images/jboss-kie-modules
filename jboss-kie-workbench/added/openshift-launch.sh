#!/bin/sh
# Openshift JBoss KIE - Workbench launch script

source $JBOSS_HOME/bin/launch/logging.sh
# Script from jboss.container.wildfly.launch-config,
# Add needed functions to execute CLI Scripts and provide the needed env to fix
# https://issues.redhat.com/browse/RHPAM-3506
source $JBOSS_HOME/bin/launch/openshift-common.sh

if [ "${SCRIPT_DEBUG}" = "true" ] ; then
    set -x
    log_info "Script debugging is enabled, allowing bash commands and their arguments to be printed as they are executed"
fi

CONFIG_FILE=$JBOSS_HOME/standalone/configuration/standalone-openshift.xml
# needed by openshift-common.sh script
WILDFLY_SERVER_CONFIGURATION=${CONFIG_FILE}
LOGGING_FILE=$JBOSS_HOME/standalone/configuration/logging.properties

# launch createConfigExecutionContext
createConfigExecutionContext

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
  $JBOSS_HOME/bin/launch/configure_logger_category.sh
  # TODO remove after elytron is fully configured
  $JBOSS_HOME/bin/launch/security-domains.sh
  $JBOSS_HOME/bin/launch/jboss_modules_system_pkgs.sh
  $JBOSS_HOME/bin/launch/keycloak.sh
  $JBOSS_HOME/bin/launch/deploymentScanner.sh
  $JBOSS_HOME/bin/launch/ports.sh
  $JBOSS_HOME/bin/launch/access_log_valve.sh
  $JBOSS_HOME/bin/launch/mp-config.sh
  $JBOSS_HOME/bin/launch/tracing.sh
  $JBOSS_HOME/bin/launch/filters.sh
  $JBOSS_HOME/bin/launch/jboss-kie-wildfly-common.sh
  $JBOSS_HOME/bin/launch/jboss-kie-workbench.sh
  $JBOSS_HOME/bin/launch/jboss-kie-wildfly-elytron.sh
  $JBOSS_HOME/bin/launch/elytron.sh
  # RHPAM-3299 - jboss-kie-wildfly-common.sh needs to run before maven-settings.sh so MAVEN_LOCAL_REPO can be correctly set
  $JBOSS_HOME/bin/launch/maven-settings.sh
  $JBOSS_HOME/bin/launch/jboss-kie-wildfly-config-files-formatter.sh
  /opt/run-java/proxy-options
)

source $JBOSS_HOME/bin/launch/configure.sh

log_info "Running $JBOSS_IMAGE_NAME image, version $JBOSS_IMAGE_VERSION"

if [ -n "$CLI_GRACEFUL_SHUTDOWN" ] ; then
  trap "" TERM
  log_info "Using CLI Graceful Shutdown instead of TERM signal"
fi

# RHPAM-1135: We need to build and pass an array otherwise spaces in passwords will break the exec
D_OPTS="${JBOSS_KIE_ARGS}"
D_DLM=" -D"
D_STR=" ${D_OPTS}${D_DLM}"
D_ARR=()
while [[ $D_STR ]]; do
    D_TMP="${D_STR%%"$D_DLM"*}"
    if [[ ! "${D_TMP}" =~ ^\ +$ ]] && [[ "x${D_TMP}" != "x" ]]; then
        D_TMP=$(eval "echo \"${D_TMP}\"")
        D_ARR+=("-D${D_TMP}")
    fi
    D_STR=${D_STR#*"$D_DLM"}
done

exec env M2_HOME=${M2_HOME} $JBOSS_HOME/bin/standalone.sh -c standalone-openshift.xml -bmanagement 127.0.0.1 \
    ${JAVA_PROXY_OPTIONS} ${JBOSS_HA_ARGS} ${JBOSS_MESSAGING_ARGS} "${D_ARR[@]}"
