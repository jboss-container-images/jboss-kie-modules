#!/usr/bin/env bats

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
export LAUNCH_DIR=$JBOSS_HOME/bin/launch
mkdir -p $LAUNCH_DIR

cp $BATS_TEST_DIRNAME/../../../tests/bats/common/launch-common.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../tests/bats/common/logging.bash $JBOSS_HOME/bin/launch/logging.sh
cp $BATS_TEST_DIRNAME/../../../jboss-kie-common/added/launch/jboss-kie-common.sh $JBOSS_HOME/bin/launch/jboss-kie-common.sh

#imports
source $BATS_TEST_DIRNAME/../../added/launch/jboss-kie-smartrouter.sh

teardown() {
    rm -rf $JBOSS_HOME
}

@test "check if kie server router ids are set as expected" {
  local expected

  # happy path
  KIE_SERVER_ROUTER_ID="my-router"
  expected="my-router"
  configure_router_state >&2
  echo "JBOSS_KIE_ARGS is ${JBOSS_KIE_ARGS}" >&2
  echo "Expected is ${expected}" >&2
  [[ $JBOSS_KIE_ARGS == *"-Dorg.kie.server.router.id=${expected}"* ]]

  # fix characters
  KIE_SERVER_ROUTER_ID=" %my route_r -"
  expected="0--my-route-r--0"
  configure_router_state >&2
  echo "JBOSS_KIE_ARGS is ${JBOSS_KIE_ARGS}" >&2
  echo "Expected is ${expected}" >&2
  [[ $JBOSS_KIE_ARGS == *"-Dorg.kie.server.router.id=${expected}"* ]]
}


@test "verify if the JAVA_MAX_MEM_RATIO is set to 80 and JAVA_INITIAL_MEM_RATIO is set to 25" {
    configure_mem_ratio
    [[ "${JAVA_MAX_MEM_RATIO}" == 80 ]]
    [[ "${JAVA_INITIAL_MEM_RATIO}" == 25 ]]
}

@test "verify if the JAVA_MAX_MEM_RATIO is set with the values passed" {
    export JAVA_INITIAL_MEM_RATIO=10
    export JAVA_MAX_MEM_RATIO=25
    configure_mem_ratio
    [[ "${JAVA_MAX_MEM_RATIO}" == 25 ]]
    [[ "${JAVA_INITIAL_MEM_RATIO}" == 10 ]]
    unset JAVA_INITIAL_MEM_RATIO
    unset JAVA_MAX_MEM_RATIO
}
