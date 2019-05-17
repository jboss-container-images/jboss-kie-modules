#!/usr/bin/env bats

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
mkdir -p $JBOSS_HOME/bin/launch

cp $BATS_TEST_DIRNAME/../../../tests/bats/common/launch-common.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../tests/bats/common/logging.bash $JBOSS_HOME/bin/launch/logging.sh

# begin mocks - import if require in future tests
touch "${JBOSS_HOME}/bin/launch/login-modules-common.sh"
touch "${JBOSS_HOME}/bin/launch/jboss-kie-common.sh"
touch "${JBOSS_HOME}/bin/launch/jboss-kie-wildfly-common.sh"
touch "${JBOSS_HOME}/bin/launch/management-common.sh"
touch "${JBOSS_HOME}/bin/launch/logging.sh"
touch "${JBOSS_HOME}/bin/launch/jboss-kie-wildfly-security.sh"

function query_route_host() {
  echo ""
}

function query_route_service_host() {
  echo ""
}

function build_route_url() {
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