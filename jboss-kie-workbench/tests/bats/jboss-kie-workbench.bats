#!/usr/bin/env bats

export OPT_DIR=${BATS_TMPDIR}/opt
export JBOSS_HOME=${OPT_DIR}/eap

mkdir -p ${OPT_DIR}/kie/data
mkdir -p ${JBOSS_HOME}/bin/launch

cp $BATS_TEST_DIRNAME/../../../tests/bats/common/launch-common.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../tests/bats/common/logging.bash $JBOSS_HOME/bin/launch/logging.sh
cp $BATS_TEST_DIRNAME/../../../jboss-kie-common/added/launch/jboss-kie-common.sh $JBOSS_HOME/bin/launch/jboss-kie-common.sh

# begin mocks - import if require in future tests
touch "${JBOSS_HOME}/bin/launch/login-modules-common.sh"
#touch "${JBOSS_HOME}/bin/launch/jboss-kie-common.sh"
touch "${JBOSS_HOME}/bin/launch/jboss-kie-wildfly-common.sh"
touch "${JBOSS_HOME}/bin/launch/management-common.sh"
touch "${JBOSS_HOME}/bin/launch/logging.sh"
touch "${JBOSS_HOME}/bin/launch/jboss-kie-wildfly-security.sh"
mkdir -p "${BATS_TMPDIR}/opt/kie/data"

function query_default_route_host() {
  echo "${WORKBENCH_ROUTE_NAME}-host"
}

function query_route_protocol() {
  echo "http"
}

function query_route_service_host() {
  echo ""
}
# end mocks

# imports
source $BATS_TEST_DIRNAME/../../added/launch/jboss-kie-workbench.sh

teardown() {
    rm -rf ${OPT_DIR}
}

@test "Make sure GIT_HOOKS_DIR was created successfully" {
    local expected="${BATS_TMPDIR}/opt/kie/data/git/hooks"
    GIT_HOOKS_DIR="${expected}"
    JBOSS_PRODUCT="businesscentral"

    configure_guvnor_settings >&2
    [ -d "${GIT_HOOKS_DIR}" ]
}

@test "Make sure APPFORMER_SSH_KEYS_STORAGE_FOLDER was created successfully" {
    local expected="${BATS_TMPDIR}/opt/kie/data/security/pkeys"
    APPFORMER_SSH_KEYS_STORAGE_FOLDER="${expected}"
    JBOSS_PRODUCT="businesscentral"

    configure_guvnor_settings >&2
    [ -d "${APPFORMER_SSH_KEYS_STORAGE_FOLDER}" ]
}

@test "Check git http protocol was enabled successfully" {
    WORKBENCH_ROUTE_NAME="businesscentral-route"
    JBOSS_KIE_ARGS=""
    local expected=$HOSTNAME
    configure_guvnor_settings >&2
    [[ $JBOSS_KIE_ARGS == *"-Dorg.uberfire.nio.git.http.enabled=true"* ]]
    [[ $JBOSS_KIE_ARGS == *"-Dorg.uberfire.nio.git.http.hostname=${expected}"* ]]
}

@test "Check maven repo url has been correctly set" {
    WORKBENCH_ROUTE_NAME="businesscentral-route"
    JBOSS_KIE_ARGS=""
    local expected="http://${HOSTNAME}:80/maven2"
    echo "Expected is ${expected}" >&2
    configure_guvnor_settings >&2
    [[ $JBOSS_KIE_ARGS == *"-Dorg.appformer.m2repo.url=${expected}"* ]]
}

@test "verify if the GC_MAX_METASPACE_SIZE is set to 1024 if WORKBENCH_MAX_METASPACE_SIZE is not set" {
    configure_metaspace
    echo "GC_MAX_METASPACE_SIZE=${GC_MAX_METASPACE_SIZE}"
    [[ "${GC_MAX_METASPACE_SIZE}" == "1024" ]]
}

@test "verify if the WORKBENCH_MAX_METASPACE_SIZE is correctly set" {
    export WORKBENCH_MAX_METASPACE_SIZE="2048"
    configure_metaspace
    echo "GC_MAX_METASPACE_SIZE=${GC_MAX_METASPACE_SIZE}"
    [[ "${GC_MAX_METASPACE_SIZE}" == "2048" ]]
}

@test "verify if the GC_MAX_METASPACE_SIZE is correctly set and bypass WORKBENCH_MAX_METASPACE_SIZE env" {
    export GC_MAX_METASPACE_SIZE="4096"
    configure_metaspace
    echo "GC_MAX_METASPACE_SIZE=${GC_MAX_METASPACE_SIZE}"
    [[ "${GC_MAX_METASPACE_SIZE}" == "4096" ]]
}

@test "verify if the WORKBENCH_MAX_METASPACE_SIZE takes precedence when WORKBENCH_MAX_METASPACE_SIZE and GC_MAX_METASPACE_SIZE are set" {
    export WORKBENCH_MAX_METASPACE_SIZE="4096"
    export GC_MAX_METASPACE_SIZE="2048"
    configure_metaspace
    echo "GC_MAX_METASPACE_SIZE=${GC_MAX_METASPACE_SIZE}"
    [[ "${GC_MAX_METASPACE_SIZE}" == "${WORKBENCH_MAX_METASPACE_SIZE}" ]]
}

