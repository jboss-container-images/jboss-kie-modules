#!/bin/bash

function prepareEnv() {
    # please keep these in alphabetical order
    unset ES_CLUSTER_NAME
    unset ES_HTTP_HOST
    unset ES_HTTP_PORT
    unset ES_JAVA_OPTS
    unset ES_MINIMUM_MASTER_NODES
    unset ES_NODE_NAME
    unset ES_TRANSPORT_HOST
    unset ES_TRANSPORT_TCP_PORT
}

function configureEnv() {
    configure
}

function preConfigure() {
    configureMinMemoryRatio
}

function configure() {
    configureJvm
    configureClusterName
    configureNodeName
    configureNetworkHost
    configurePorts
    configureMinimumMasterNodes
}

function configureMinMemoryRatio() {
    # When container memory limit is set, we need to force min and max memory to be equal
    export JAVA_INITIAL_MEM_RATIO=100
}

function configureMinimumMasterNodes() {
    local initial_master_nodes=${ES_MINIMUM_MASTER_NODES:-1}
    ELASTICSEARCH_ARGS="${ELASTICSEARCH_ARGS} -Ediscovery.zen.minimum_master_nodes=${initial_master_nodes}"
}

function configureJvm() {
    # All the JVM settings are inherited from jboss/openjdk18-rhel7 image
    # to manually set the memory use $ES_OPTS_APPEND var on OpenShift
    JAVA_OPTS="$(adjust_java_options ${ES_JAVA_OPTS})"

    # If there is no memory setting, the default will be applied.
    local default_max_mem="1024m"
    if [[ "${JAVA_OPTS}" != *"-Xmx"* ]] && [[ "${JAVA_OPTS}" != *"-Xms"* ]]; then
        JAVA_OPTS="-Xms${default_max_mem} -Xmx${default_max_mem} ${JAVA_OPTS}"
     fi

    for i in ${JAVA_OPTS}; do
        echo $i >> ${ELASTICSEARCH_HOME}/config/jvm.options
    done
}

function configureClusterName() {
    local cluster_name="${ES_CLUSTER_NAME:-kie-cluster}"
    ELASTICSEARCH_ARGS="${ELASTICSEARCH_ARGS} -Ecluster.name=${cluster_name}"
}

function configureNodeName() {
    local node_name=${ES_NODE_NAME:-${HOSTNAME}}
    ELASTICSEARCH_ARGS="${ELASTICSEARCH_ARGS} -Enode.name=${node_name}"
}

function configureNetworkHost() {
    local container_ip_address=`hostname -i`
    local network_host=${ES_HTTP_HOST:-${container_ip_address}}
    local transport_host=${ES_TRANSPORT_HOST:-${container_ip_address}}
    ELASTICSEARCH_ARGS="${ELASTICSEARCH_ARGS} -Ehttp.host=${network_host} -Etransport.host=${transport_host}"
}

function configurePorts() {
    local http_port=${ES_HTTP_PORT:-9200}
    local transport_tcp_port=${ES_TRANSPORT_TCP_PORT:-9300}
    ELASTICSEARCH_ARGS="${ELASTICSEARCH_ARGS} -Etransport.tcp.port=${transport_tcp_port} -Ehttp.port=${http_port}"
}
