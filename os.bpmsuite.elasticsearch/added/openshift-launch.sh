#!/bin/sh
# Openshift BPM Suite Elasticsearch launch script

if [ "${SCRIPT_DEBUG}" = "true" ] ; then
    set -x
    echo "Script debugging is enabled, allowing bash commands and their arguments to be printed as they are executed"
fi

CONFIGURE_SCRIPTS=(
    $ELASTICSEARCH_HOME/bin/launch/bpmsuite-elasticsearch.sh
    /opt/run-java/proxy-options
)

source /usr/local/dynamic-resources/dynamic_resources.sh
source $ELASTICSEARCH_HOME/bin/launch/configure.sh

echo "Running $JBOSS_IMAGE_NAME image, version $JBOSS_IMAGE_VERSION"

exec $ELASTICSEARCH_HOME/bin/elasticsearch ${ELASTICSEARCH_ARGS}
