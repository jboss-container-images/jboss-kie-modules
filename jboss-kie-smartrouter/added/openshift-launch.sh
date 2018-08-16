#!/bin/sh
# Openshift BPMS Smart Router launch script

source ${LAUNCH_DIR}/logging.sh

if [ "${SCRIPT_DEBUG}" = "true" ] ; then
    set -x
    log_info "Script debugging is enabled, allowing bash commands and their arguments to be printed as they are executed"
fi

CONFIGURE_SCRIPTS=(
  ${LAUNCH_DIR}/jboss-kie-smartrouter.sh
)

source ${LAUNCH_DIR}/configure.sh

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

exec ${JAVA_HOME}/bin/java "${D_ARR[@]}" -jar /opt/${JBOSS_PRODUCT}/${KIE_ROUTER_DISTRIBUTION_JAR}
