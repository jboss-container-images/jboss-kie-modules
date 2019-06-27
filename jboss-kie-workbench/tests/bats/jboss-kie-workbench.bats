#!/usr/bin/env bats

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
mkdir -p $JBOSS_HOME/bin/launch

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
    rm -rf $JBOSS_HOME
}

@test "Make sure GIT_HOOKS_DIR was created successfully" {
    local expected="${JBOSS_HOME}/opt/kie/data/git/hooks"
    GIT_HOOKS_DIR="${expected}"
    JBOSS_PRODUCT="businesscentral"

    configure_guvnor_settings >&2
    [ -d "${GIT_HOOKS_DIR}" ]
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