#!/usr/bin/env bats
export JBOSS_HOME=$BATS_TMPDIR/jboss_home
export LAUNCH_DIR=$JBOSS_HOME/bin/launch
export CONFIG_DIR=/tmp
mkdir -p $LAUNCH_DIR

cp $BATS_TEST_DIRNAME/../../../tests/bats/common/launch-common.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../tests/bats/common/logging.bash $JBOSS_HOME/bin/launch/logging.sh
cp $BATS_TEST_DIRNAME/../../../jboss-kie-common/added/launch/jboss-kie-common.sh $JBOSS_HOME/bin/launch/jboss-kie-common.sh

#imports
source $BATS_TEST_DIRNAME/../../added/launch/jboss-kie-smartrouter.sh

setup() {
  rm -rf /tmp/logging.properties || true
  cp $BATS_TEST_DIRNAME/../../added/configuration/logging.properties ${CONFIG_DIR}/logging.properties
}

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

@test "verify the env vars when LOG_LEVEL is set" {
    LOG_LEVEL="WARN"
    LOGGER_CATEGORIES=org.xyz=FINEST,com.acme=SEVERE,org.drools=FINE
    configure_logger_config_file
    file1=$CONFIG_DIR/logging.properties
    file2=$BATS_TEST_DIRNAME/expectations/logging-expected_warn.properties
    local result="$(diff -q "$file1" "$file2")"
    [[ $result == "" ]]
    [[ "${JAVA_OPTS_APPEND}" ==  " -Djava.util.logging.config.file=/tmp/logging.properties" ]]
}

@test "verify the logger.properties with default values" {
    configure_logger_config_file
    file1=$CONFIG_DIR/logging.properties
    file2=$BATS_TEST_DIRNAME/expectations/logging-expected_default.properties
    local result="$(diff -q "$file1" "$file2")"
    [[ $result == "" ]]
}

@test "verify the logger.properties when is set LOG_LEVEL" {
    LOG_LEVEL=SEVERE
    LOGGER_CATEGORIES=org.xyz=INFO,com.acme=DEBUG
    configure_logger_config_file
    file1=$CONFIG_DIR/logging.properties
    file2=$BATS_TEST_DIRNAME/expectations/logging-expected.properties
    local result="$(diff -q "$file1" "$file2")"
    [[ $result == "" ]]
}

@test "verify the logger.properties when LOG_LEVEL is unset" {
    LOGGER_CATEGORIES=org.xyz=INFO,com.acme=DEBUG
    configure_logger_config_file
    file1=$CONFIG_DIR/logging.properties
    file2=$BATS_TEST_DIRNAME/expectations/logging-log_level_default.properties
    local result="$(diff -q "$file1" "$file2")"
    [[ $result == "" ]]
}

@test "verify the logger.properties when LOGGER_CATEGORIES is unset" {
    configure_logger_config_file
    file1=$CONFIG_DIR/logging.properties
    file2=$BATS_TEST_DIRNAME/expectations/logging-packages_log_level_default.properties
    local result="$(diff -q "$file1" "$file2")"
    [[ $result == "" ]]
}

@test "verify the message when a LOG_LEVEL is not allowed " {
    LOG_LEVEL=SUPERDEFINED
    run configure_logger_config_file
    [ "${output}" = "[WARN]Log Level SUPERDEFINED is not allowed, the allowed levels are ALL CONFIG FINE FINER FINEST INFO OFF SEVERE WARNING" ]
}