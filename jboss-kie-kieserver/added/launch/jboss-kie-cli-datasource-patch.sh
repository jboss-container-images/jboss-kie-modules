#!/usr/bin/env bash
# Note that, this is a temporary script until https://issues.jboss.org/browse/CLOUD-2903
# TODO: remove it once the fix for the issue above is available. Follow up task https://issues.jboss.org/browse/KIECLOUD-311
#
# It's purpose is to add two xa-pool properties for XA datasources which are not exposed
# by environment variables on EAP datasource configuration script.
#
# This script will accept only two envs:
#
# ${DATASOURCE_PREFIX}_IS_SAME_RM_OVERRIDE
# /subsystem=datasources/xa-data-source=test-TEST:write-attribute(name=same-rm-override, value=true)
#           Should result on <is-same-rm-override>true</is-same-rm-override>
# ${DATASOURCE_PREFIX}_NO_TX_SEPARATE_POOLS
# /subsystem=datasources/xa-data-source=test-TEST:write-attribute(name=no-tx-separate-pool,value=true)
#           Should result on <no-tx-separate-pools>true</no-tx-separate-pools>
#
source "${JBOSS_HOME}/bin/launch/launch-common.sh"
source "${JBOSS_HOME}/bin/launch/logging.sh"

function configure() {
    override_xa_datasource
}

function override_xa_datasource() {
    local patch_needed="FALSE"

    for dsPrefix in $(echo $DATASOURCES | sed "s/,/ /g"); do
        nonxa=$(find_env "${dsPrefix}_NONXA")

        if [ "${nonxa^^}" == "FALSE" ]; then

            is_same_rm_override=$(find_env "${dsPrefix}_IS_SAME_RM_OVERRIDE")
            no_tx_separate_pools=$(find_env "${dsPrefix}_NO_TX_SEPARATE_POOLS")

            # not set by default, needs to allow to set true or false.
            if [ "${is_same_rm_override^^}" == "TRUE" ]; then
                local value="true"
                if [ "${is_same_rm_override^^}" == "FALSE" ]; then
                    value="false"
                fi
                patch_needed="TRUE"
                echo "/subsystem=datasources/xa-data-source=${dsPrefix,,}-${dsPrefix^^}:write-attribute(name=same-rm-override, value=${value})" >> /tmp/datasource-patch.cli
            fi
            # no need to set false value since its default value is false.
            if [ "${no_tx_separate_pools^^}" == "TRUE" ]; then
                patch_needed="TRUE"
                echo "/subsystem=datasources/xa-data-source=${dsPrefix,,}-${dsPrefix^^}:write-attribute(name=no-tx-separate-pool, value=true)" >> /tmp/datasource-patch.cli
            fi
        fi
    done

    if [ "${patch_needed^^}" == "TRUE" ]; then
        # last, add shutdown instruction to stop eap admin mode
        echo "shutdown" >> /tmp/datasource-patch.cli

        log_info "Starting EAP on admin-only mode to apply post datasource configuration."
        $JBOSS_HOME/bin/standalone.sh --admin-only --server-config="standalone-openshift.xml" &
        JBOSS_PID=$(echo $!)

        # wait eap finish to start on admin mode
        start=$(date +%s)
        end=$((start + 120))
        until $JBOSS_HOME/bin/jboss-cli.sh --command="connect" || [ $(date +%s) -ge "$end" ]; do
            sleep 5
        done

        log_info "Executing the following cli commands: "
        log_info "`cat /tmp/datasource-patch.cli`"

        $JBOSS_HOME/bin/jboss-cli.sh --connect --file=/tmp/datasource-patch.cli
        if [ $? -ne 0 ]; then
            kill -15 $JBOSS_PID
        fi
        log_info "The file /tmp/datasource-patch.cli will be kept for further review."
    fi
}

