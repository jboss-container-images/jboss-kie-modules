#!/bin/sh
# if using vim, do ':set ft=zsh' for easier reading

# source the KIE config
source $JBOSS_HOME/bin/launch/kieserver-env.sh
source $JBOSS_HOME/bin/launch/logging.sh
# set the KIE environment
setKieEnv
# dump the KIE environment
dumpKieEnv

function verifyServerContainers() {
    if [ "${KIE_SERVER_CONTAINER_DEPLOYMENT}" != "" ]; then
        local releaseIds=""
        for (( i=0; i<${KIE_SERVER_CONTAINER_DEPLOYMENT_COUNT}; i++ )); do
            local groupId=$(getKieServerContainerVal KJAR_GROUP_ID ${i})
            local artifactId=$(getKieServerContainerVal KJAR_ARTIFACT_ID ${i})
            local version=$(getKieServerContainerVal KJAR_VERSION ${i})
            releaseIds="${releaseIds} ${groupId}:${artifactId}:${version}"
        done
        local containerVerifier="org.kie.server.services.impl.KieServerContainerVerifier"
        log_info "Attempting to verify kie server containers with 'java ${containerVerifier} ${releaseIds}' with custom Java properties '${JAVA_OPTS_APPEND}'"
        # Workaround for RHPAM-4849
        if [ -x "$(command -v java)" ]; then
            java ${JAVA_OPTS_APPEND} $(getKieJavaArgs) ${containerVerifier} ${releaseIds}
        else
            log_warning "java symlink in /usr/bin not found, using JAVA_HOME $JAVA_HOME instead to run verification."
            $JAVA_HOME/bin/java ${JAVA_OPTS_APPEND} $(getKieJavaArgs) ${containerVerifier} ${releaseIds}
        fi
    fi
}

# Execute the server container verification
if [ "${KIE_SERVER_DISABLE_KC_VERIFICATION^^}" != "TRUE" ]; then
    verifyServerContainers
    ERR=$?

    if [ $ERR -ne 0 ]; then
      log_error "Aborting due to error code $ERR from kie server container verification"
      exit $ERR
    fi
else
    log_warning "KIE Jar verification disabled, skipping. Please make sure that the provided KJar was properly tested before deploying it."
fi

# Necessary to permit running with a randomised UID
chown -R --quiet jboss:root ${HOME}/.m2/repository
chmod -R --quiet g+rwX ${HOME}/.m2/repository

exit 0
