#!/bin/bash

source "${JBOSS_HOME}/bin/launch/launch-common.sh"
source "${JBOSS_HOME}/bin/launch/jboss-kie-common.sh"
source "${JBOSS_HOME}/bin/launch/logging.sh"

# Hooks script applies to OpenShiftStartupStrategy only
startupStrategy=$(find_env "KIE_SERVER_STARTUP_STRATEGY")

# make sure there is a workbench service within the namespace.
controllerServiceName=${WORKBENCH_SERVICE_NAME//-/_}
controllerServiceHost=$(find_env "${controllerServiceName^^}_SERVICE_HOST")
controllerServicePort=$(find_env "${controllerServiceName^^}_SERVICE_PORT_HTTP")

# KIE Server default state when scaled down to 0 
state="DETACHED"
kieCMName=""

check_kieserver_state() {
    local uri="configmaps?labelSelector=services.server.kie.org%2Fkie-server-id%3D${KIE_SERVER_ID}"
    local resp=$(query_ocp_api "api" "${uri}")
    state=$(echo ${resp:: -3} | python -c 'import json,sys;obj=json.load(sys.stdin);print (obj["items"][0]["metadata"]["labels"]["services.server.kie.org/kie-server-state"])' 2>/dev/null)
    kieCMName=$(echo ${resp:: -3} | python -c 'import json,sys;obj=json.load(sys.stdin);print (obj["items"][0]["metadata"]["name"])' 2>/dev/null)
    if [[ -z "$state" ]]; then
        state="DETACHED"
    fi
}

# param
# ${1} - when scale up or down
check_state_loop() {
    local scaleUporDown=${1}
    for ((i = 0; i < 15; i++)); do
        check_kieserver_state
        if [[ "$scaleUporDown" == "up" ]] && [[ "$state" != "DETACHED" ]]; then
            break;
        fi
        if [[ "$scaleUporDown" == "down" ]] && [[ "$state" == "DETACHED" ]]; then
            break;
        fi
        sleep 3
    done
}

# param
# ${1} - the config map payload
# ${2} - ConfigMap name
update_config_map() {
    local payload=${1}
    local kieCMName=${2}
    # only execute the following lines if this container is running on OpenShift
    if [ -e /var/run/secrets/kubernetes.io/serviceaccount/token ]; then
        local namespace=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
        local token=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
        local response=$(curl -s --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
            -H "Authorization: Bearer $token" \
            -H 'Accept: application/json' \
            -H 'Content-Type: application/strategic-merge-patch+json' \
            -XPATCH \
            ${KUBERNETES_SERVICE_PROTOCOL:-https}://${KUBERNETES_SERVICE_HOST:-kubernetes.default.svc}:${KUBERNETES_SERVICE_PORT:-443}/api/v1/namespaces/${namespace}/configmaps/${kieCMName} -d ${payload} )
    fi
}

if [ ${startupStrategy} == "OpenShiftStartupStrategy" -a -n ${WORKBENCH_SERVICE_NAME} -a -n "${KIE_SERVER_ID}" ]; then
    check_kieserver_state
    kieServeruri="deploymentconfigs?labelSelector=services.server.kie.org%2Fkie-server-id%3D${KIE_SERVER_ID}"
    kieResponse=$(query_ocp_api "apis/apps.openshift.io" "${kieServeruri}")
    kieReplicas=$(echo ${kieResponse:: -3} | python -c 'import json,sys;obj=json.load(sys.stdin);print (obj["items"][0]["spec"]["replicas"])')
    kieDCName=$(echo ${kieResponse:: -3} | python -c 'import json,sys;obj=json.load(sys.stdin);print (obj["items"][0]["metadata"]["name"])')
    if [[ -z "$kieReplicas" ]]; then
        kieReplicas=0
        state="DETACHED"
    fi

    controllerResponse=$(query_ocp_api "apis/apps.openshift.io" "deploymentconfigs/${WORKBENCH_SERVICE_NAME}")
    controllerReplicas=$(echo ${controllerResponse:: -3} | python -c 'import json,sys;obj=json.load(sys.stdin);print (obj["spec"]["replicas"])')
    controllerAuth="$(echo -n "${KIE_ADMIN_USER}:${KIE_ADMIN_PWD}" | base64)"

    if [ ${kieReplicas} == 0 ]; then
        # Normal scaling down scenario triggered by 'oc scale' command
        if [ "$state" != "DETACHED" ]; then    
            log_info "KIE Server Replicas is ${kieReplicas}, updating ${KIE_SERVER_ID} configMap to DETACHED."
            update_config_map "{\"metadata\":{\"labels\":{\"services.server.kie.org/kie-server-state\":\"DETACHED\"}}}" "${kieCMName}"
            check_state_loop "down"
            sleep 10 # Wait for ServerTemplate cache to expire
        fi
        # Deleting KieServer DC scenario
        if [ "$state" == "DETACHED" -a "${controllerServiceHost}x" != "x" -a "${controllerServicePort}x" != "x" -a ${controllerReplicas} -gt 0  ]; then
            # curl command may be hanging a bit during dc pod starting up; need to update
            # Pod.spec.terminationGracePeriodSeconds so as to safe guard infinite wait
            # and also accommodate bc Pod startup time.
            # try 12 times waiting 10 seconds for new retry, max allowed time is 120s
            curl --retry 12 --retry-delay 10 --retry-max-time 120 \
                -s -X DELETE -i "http://${controllerServiceHost}:${controllerServicePort}/rest/controller/server/${KIE_SERVER_ID}" \
                -H "Content-Type: application/json" \
                -H "Authorization: Basic ${controllerAuth}" 
            log_info "Controller successfully notified"
        else
            log_warning "Notify Controller failed"
        fi
    elif [ ${kieReplicas} -gt 0 ]; then
        log_info "KIE Server Replicas is ${kieReplicas}, notifying Controller for KIE Server: [${KIE_SERVER_ID}]."
        log_info "Waiting for KIE Server: [${KIE_SERVER_ID}] to scale up for 45 seconds..."
        check_state_loop "up"
        if [ "${controllerServiceHost}x" != "x" -a "${controllerServicePort}x" != "x" -a ${controllerReplicas} -gt 0  ]; then
            if [ "$state" != "DETACHED" ]; then
                # Normal scale up scenario
                # curl command may be hanging a bit during dc pod starting up; need to update
                # Pod.spec.terminationGracePeriodSeconds so as to safe guard infinite wait
                # and also accommodate bc Pod startup time.
                # try 12 times waiting 10 seconds for new retry, max allowed time is 120s
                curl --retry 12 --retry-delay 10 --retry-max-time 120 \
                    -s -X PUT -i "http://${controllerServiceHost}:${controllerServicePort}/rest/controller/server/${KIE_SERVER_ID}" \
                    -H "Content-Type: application/json" \
                    -H "Authorization: Basic ${controllerAuth}"
            else
                # Deleting KieServer DC scenario
                curl --retry 12 --retry-delay 10 --retry-max-time 120 \
                    -s -X DELETE -i "http://${controllerServiceHost}:${controllerServicePort}/rest/controller/server/${KIE_SERVER_ID}" \
                    -H "Content-Type: application/json" \
                    -H "Authorization: Basic ${controllerAuth}"
            fi
            log_info "Controller successfully notified"
        else
            log_warning "Notify Controller failed"
        fi
    fi
else
    log_warning "Not supported startup strategy, or no Controller found, or KIE_SERVER_ID is not set, skipping..."
fi
