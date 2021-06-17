#!/bin/sh
# Openshift JBoss KIE - Smart Router launch script

source ${LAUNCH_DIR}/logging.sh

if [ "${SCRIPT_DEBUG}" = "true" ] ; then
    set -x
    SHOW_JVM_SETTINGS="-XshowSettings:properties"
    log_info "Script debugging is enabled, allowing bash commands and their arguments to be printed as they are executed"
    log_info "JVM settings debug is enabled."
fi

CONFIGURE_SCRIPTS=(
  ${LAUNCH_DIR}/jboss-kie-smartrouter.sh
  /opt/run-java/proxy-options
)

source ${LAUNCH_DIR}/configure.sh

# for JVM property settings please refer to this link https://github.com/jboss-openshift/cct_module/blob/0.39.x/jboss/container/java/jvm/api/module.yaml
source /usr/local/dynamic-resources/dynamic_resources.sh
JAVA_OPTS="$(adjust_java_options ${JAVA_OPTS})"

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

# handle JAVA_OPTS_APPEND at startup
exec ${JAVA_HOME}/bin/java ${SHOW_JVM_SETTINGS} ${JAVA_OPTS} ${JAVA_OPTS_APPEND} ${JAVA_PROXY_OPTIONS} "${D_ARR[@]}" -jar /opt/${JBOSS_PRODUCT}/${KIE_ROUTER_DISTRIBUTION_JAR}
