#!/usr/bin/env bash

source "${LAUNCH_DIR}/jboss-kie-pim-common.sh"
source "${LAUNCH_DIR}/launch-common.sh"
source "${LAUNCH_DIR}/logging.sh"

function configureEnv() {
    configure
}

function configure() {
    augment_app
}

function augment_app() {
    if [ "${SCRIPT_DEBUG}" = "true" ] ; then
        verbose="v"
        SHOW_JVM_SETTINGS="-XshowSettings:properties"
    fi

    local db_kind_prop=""
    if [ -f ${CONFIG_DIR}/application.yaml ]; then
        log_info "${CONFIG_DIR}/application.yaml exists, search db-kind for augmentation..."
        db_kind=$(trim `cat ${CONFIG_DIR}/application.yaml | grep db-kind | cut -d: -f2`)
        if [ "${db_kind}x" != "x" ]; then
            db_kind_prop="-Dquarkus.datasource.db-kind=${db_kind}"
            log_info "db-kind set to ${db_kind}."
        fi
    fi

    log_info "Re-augmenting Quarkus Application to apply custom configurations..."
    cd $JBOSS_HOME/quarkus-app && $JAVA_HOME/bin/java -jar ${SHOW_JVM_SETTINGS} -Dquarkus.launch.rebuild=true ${db_kind_prop} quarkus-run.jar

    # after re-augmented, the lib/deployment directory can be deleted to save some space on the Container Image.
    log_info "Re-augmentation is complete, deleting deployment directory..."
    rm -rf${verbose} $JBOSS_HOME/quarkus-app/lib/deployment
}