#!/bin/bash

source "${JBOSS_HOME}/bin/launch/launch-common.sh"
source "${JBOSS_HOME}/bin/launch/logging.sh"
source "${JBOSS_HOME}/bin/launch/jboss-kie-wildfly-security.sh"

function prepareEnv() {
    # please keep these in alphabetical order
    DASHBUILDER_ALLOW_EXTERNAL_FILE_REGISTER
    DASHBUILDER_COMP_ENABLE
    DASHBUILDER_COMPONENT_PARTITION
    DASHBUILDER_DATASET_PARTITION
    DASHBUILDER_EXTERNAL_COMP_DIR
    DASHBUILDER_CONFIG_MAP_PROPS
    DASHBUILDER_IMPORT_FILE_LOCATION
    DASHBUILDER_IMPORTS_BASE_DIR
    DASHBUILDER_MODEL_FILE_REMOVAL
    DASHBUILDER_MODEL_UPDATE
    DASHBUILDER_RUNTIME_MULTIPLE_IMPORT
    DASHBUILDER_UPLOAD_SIZE
    KIESERVER_DATASETS
    KIESERVER_SERVER_TEMPLATES
    unset_kie_security_env
}

function configureEnv() {
    configure
}

function configure() {
    configure_dashbuilder_auth
    configure_dashbuilder_allow_external
    configure_dashbuilder_partitions
    configure_dashbuilder_file_imports
    configure_dasbuilder_file_import_properties
    configure_dashbuilder_external_component
    configure_dashbuilder_kieserver_dataset
    configure_dashbuilder_kieserver_server_template
    # must be the last to be executed.
    dashbuilder_process_properties_file
}

function configure_dashbuilder_auth() {
    # add eap user (see jboss-kie-wildfly-security.sh)
    add_kie_admin_user
}

function configure_dashbuilder_allow_external() {
    local allow_external="false"
    if [ "${DASHBUILDER_ALLOW_EXTERNAL_FILE_REGISTER^^}" = "TRUE" ]; then
        allow_external="true"
    fi
    JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.runtime.allowExternal=${allow_external}"
}

# Configures dashbuilder.dataset.partition and dashbuilder.components.partition properties
function configure_dashbuilder_partitions() {
    local component_partition="true"
    local dataset_partition="true"
    if [ "${DASHBUILDER_COMPONENT_PARTITION^^}" = "FALSE" ]; then
        component_partition="false"
    fi
    if [ "${DASHBUILDER_DATASET_PARTITION^^}" = "FALSE" ]; then
        dataset_partition="false"
    fi

    JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.components.partition=${component_partition}"
    JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.dataset.partition=${dataset_partition}"
}

function configure_dashbuilder_file_imports() {
    local kie_data_import_dir="/opt/kie/data/imports"

    if [ -n "${DASHBUILDER_IMPORT_FILE_LOCATION}" ]; then
        # error handling is done by dashbuilder application
        # ERROR [org.dashbuilder.backend.services.impl.RuntimeModelRegistryImpl] (MSC service thread 1-6) File does not exist: /some_dir
        log_info "DASHBUILDER_IMPORT_FILE_LOCATION is set to ${DASHBUILDER_IMPORT_FILE_LOCATION}, please make sure it is available otherwise Dashbuilder will fail to start."
        JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.runtime.import=${DASHBUILDER_IMPORT_FILE_LOCATION}"

    else
        if [ ! -d "$DASHBUILDER_IMPORTS_BASE_DIR" ]; then
            if [ "${DASHBUILDER_IMPORTS_BASE_DIR}x" != "x" ]; then
                log_warning "The directory [${DASHBUILDER_IMPORTS_BASE_DIR}] set using DASHBUILDER_IMPORTS_BASE_DIR env does not exist, using the default [${kie_data_import_dir}]"
            fi
        else
            kie_data_import_dir="${DASHBUILDER_IMPORTS_BASE_DIR}"
        fi
        log_info "Dashbuilder file location import dir is ${kie_data_import_dir}"
        JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.import.base.dir=${kie_data_import_dir}"

        if [ "${DASHBUILDER_MODEL_UPDATE^^}" = "FALSE" ]; then
            JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.model.update=false"
        fi

        local remove_model_file="false"
        if [ "${DASHBUILDER_MODEL_FILE_REMOVAL^^}" = "TRUE" ]; then
            remove_model_file="true"
        fi
        JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.removeModelFile=${remove_model_file}"
    fi
}

function configure_dasbuilder_file_import_properties() {
    local multi_import="false"
    if [ "${DASHBUILDER_RUNTIME_MULTIPLE_IMPORT^^}" = "TRUE" ]; then
        multi_import="true"
    fi

    if [ -n "${DASHBUILDER_UPLOAD_SIZE}" ]; then
        # value parse is made by dashbuilder application, if a invalid value is set it will rely on the default one.
        JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.runtime.upload.size=${DASHBUILDER_UPLOAD_SIZE}"
    fi

    JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.runtime.multi=${multi_import}"
}

function configure_dashbuilder_external_component() {
    local kie_data_external_comp_dir="/opt/kie/data/components"
    if [ "${DASHBUILDER_COMP_ENABLE^^}" = "TRUE" ]; then

        if [ ! -d "${DASHBUILDER_EXTERNAL_COMP_DIR}" ]; then
            if [ "${DASHBUILDER_EXTERNAL_COMP_DIR}x" != "x" ]; then
                log_warning "The directory [${DASHBUILDER_EXTERNAL_COMP_DIR}] set using DASHBUILDER_EXTERNAL_COMP_DIR env does not exist, the default [${kie_data_external_comp_dir}]"
            fi
        else
            kie_data_external_comp_dir="${DASHBUILDER_EXTERNAL_COMP_DIR}"
        fi
        log_info "Dashbuilder external component enabled, component dir is ${kie_data_external_comp_dir}"

        JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.components.enable=true"
        JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.components.dir=${kie_data_external_comp_dir}"
    fi
}

function configure_dashbuilder_kieserver_dataset() {

    IFS=',' read -a ks_datasets <<< $KIESERVER_DATASETS

    for ks_dataset in ${ks_datasets[@]}; do
        location=$(find_env "${ks_dataset}_LOCATION")
        replace_query=$(find_env "${ks_dataset}_REPLACE_QUERY" "false")
        user=$(find_env "${ks_dataset}_USER")
        password=$(find_env "${ks_dataset}_PASSWORD")
        token=$(find_env "${ks_dataset}_TOKEN")

        if [ "${token}x" != "x" ]; then
            log_info "Using token for dataset ${ks_dataset}."
            JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.kieserver.dataset.${ks_dataset}.location=${location}"
            JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.kieserver.dataset.${ks_dataset}.replace_query=${replace_query}"
            JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.kieserver.dataset.${ks_dataset}.token=${token}"
        else
            log_info "Token not provided, configuring user/passwd for dataset ${ks_dataset}."
            if [ "${user}x" = "x" ] || [ "${password}x" = "x" ]; then
                log_warning "User or Password Empty, dataset ${ks_dataset} not configured."
            else
                log_info "Setting properties for dataset ${ks_dataset}."
                JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.kieserver.dataset.${ks_dataset}.location=${location}"
                JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.kieserver.dataset.${ks_dataset}.replace_query=${replace_query}"
                JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.kieserver.dataset.${ks_dataset}.user=${user}"
                JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.kieserver.dataset.${ks_dataset}.password=${password}"
            fi
        fi
    done
}

function configure_dashbuilder_kieserver_server_template() {

    IFS=',' read -a ks_server_templates <<< $KIESERVER_SERVER_TEMPLATES

    for ks_server_template in ${ks_server_templates[@]}; do
        location=$(find_env "${ks_server_template}_LOCATION")
        replace_query=$(find_env "${ks_server_template}_REPLACE_QUERY" "false")
        user=$(find_env "${ks_server_template}_USER")
        password=$(find_env "${ks_server_template}_PASSWORD")
        token=$(find_env "${ks_server_template}_TOKEN")

        if [ "${token}x" != "x" ]; then
            log_info "Using token for server template ${ks_server_template}."
            JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.kieserver.serverTemplate.${ks_server_template}.location=${location}"
            JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.kieserver.serverTemplate.${ks_server_template}.replace_query=${replace_query}"
            JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.kieserver.serverTemplate.${ks_server_template}.token=${token}"
        else
            log_info "Token not provided, configuring user/passwd for server template ${ks_server_template}."
            if [ "${user}x" = "x" ] || [ "${password}x" = "x" ]; then
                log_warning "User or Password Empty, server template ${ks_server_template} not configured."
            else
                log_info "Setting properties for server template ${ks_server_template}."
                JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.kieserver.serverTemplate.${ks_server_template}.location=${location}"
                JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.kieserver.serverTemplate.${ks_server_template}.replace_query=${replace_query}"
                JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.kieserver.serverTemplate.${ks_server_template}.user=${user}"
                JBOSS_KIE_DASHBUILDER_ARGS="${JBOSS_KIE_DASHBUILDER_ARGS} -Ddashbuilder.kieserver.serverTemplate.${ks_server_template}.password=${password}"
            fi
        fi
    done
}

function dashbuilder_process_properties_file() {
    # transform the ${JBOSS_KIE_DASHBUILDER_ARGS} env into array
    IFS=' ' read -r -a jboss_kie_dashbuilder_args <<< "${JBOSS_KIE_DASHBUILDER_ARGS}"

    if [ -f "${DASHBUILDER_CONFIG_MAP_PROPS}" ]; then
        log_info "Using properties file provided by ${DASHBUILDER_CONFIG_MAP_PROPS}. The properties on this file are not validated, please make sure that all properties are valid."

        for p_from_file in `cat ${DASHBUILDER_CONFIG_MAP_PROPS}`; do
            if [[ "${jboss_kie_dashbuilder_args[@]}" == *"${p_from_file%=*}"* ]]; then
                for i in "${!jboss_kie_dashbuilder_args[@]}"; do
                    if [[ ${jboss_kie_dashbuilder_args[$i]} == *"${p_from_file%=*}"* ]]; then
                        log_info "${p_from_file%=*} is set by both, keeping value from properties file: ${p_from_file}"
                        jboss_kie_dashbuilder_args[$i]="-D${p_from_file}"
                    fi
                done
            else
                jboss_kie_dashbuilder_args[${#jboss_kie_dashbuilder_args[@]}]="-D${p_from_file}"
            fi
        done
        JBOSS_KIE_DASHBUILDER_ARGS="${jboss_kie_dashbuilder_args[@]}"
        log_info "Processed properties from ${DASHBUILDER_CONFIG_MAP_PROPS}"
        log_info "Applied properties are: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    fi
}
