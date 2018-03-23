#!/bin/sh

set -e

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added

echo "Elasticsearch Openshift image version ${ELASTICSEARCH_VERSION}"

cp -p ${ADDED_DIR}/openshift-launch.sh ${ELASTICSEARCH_HOME}/bin/

mkdir ${ELASTICSEARCH_HOME}/bin/launch
mv ${ADDED_DIR}/launch/jvm.options $ELASTICSEARCH_HOME/config/jvm.options
cp -rpv ${ADDED_DIR}/launch/* ${ELASTICSEARCH_HOME}/bin/launch
chmod ug+x ${ELASTICSEARCH_HOME}/bin/openshift-launch.sh
# Necessary to permit running with a randomised UID
chown -R jboss:root ${ELASTICSEARCH_HOME}
chmod -R g+rwX ${ELASTICSEARCH_HOME}


DATA_DIR="${ELASTICSEARCH_HOME}/data"
mkdir ${DATA_DIR}
chown -R jboss:root ${DATA_DIR}
chmod -R 777 ${DATA_DIR}