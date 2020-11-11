#!/bin/bash
# Openshift JBoss KIE - Process migration launch script

source "${LAUNCH_DIR}/logging.sh"

if [ "${SCRIPT_DEBUG}" = "true" ] ; then
    set -x
    SHOW_JVM_SETTINGS="-XshowSettings:properties"
    log_info "Script debugging is enabled, allowing bash commands and their arguments to be printed as they are executed"
    log_info "JVM settings debug is enabled."
fi

CONFIGURE_SCRIPTS=(
  "${LAUNCH_DIR}/jboss-kie-process-migration.sh"
)

source "${LAUNCH_DIR}/configure.sh"
source /usr/local/dynamic-resources/dynamic_resources.sh

log_info "Running $JBOSS_IMAGE_NAME image, version $PRODUCT_VERSION"

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

# shellcheck disable=SC2086
exec ${JAVA_HOME}/bin/java ${SHOW_JVM_SETTINGS} "${D_ARR[@]}" ${JBOSS_KIE_EXTRA_CLASSPATH} -jar /opt/${JBOSS_PRODUCT}/${KIE_PROCESS_MIGRATION_DISTRIBUTION_JAR} -s${CONFIG_DIR}/project-cloud.yml ${JBOSS_KIE_EXTRA_CONFIG}
