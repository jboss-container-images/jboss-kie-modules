#!/usr/bin/env bats

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
export LAUNCH_DIR=$JBOSS_HOME/bin/launch
export CONFIG_DIR=$JBOSS_HOME/configuration
mkdir -p $LAUNCH_DIR

cp $BATS_TEST_DIRNAME/../../../tests/bats/common/launch-common.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../tests/bats/common/logging.bash $JBOSS_HOME/bin/launch/logging.sh
cp $BATS_TEST_DIRNAME/../../../jboss-kie-common/added/launch/jboss-kie-common.sh $JBOSS_HOME/bin/launch/jboss-kie-common.sh

#imports
source $BATS_TEST_DIRNAME/../../added/launch/jboss-kie-process-migration.sh

setup() {
  cp -r $BATS_TEST_DIRNAME/../../added/configuration $JBOSS_HOME/configuration
}

teardown() {
    rm -rf $JBOSS_HOME
}

@test "check if extra classpath is set correctly" {
  local expected

  JBOSS_KIE_EXTRA_CLASSPATH="mysql-driver.jar"
  expected="-Dthorntail.classpath=mysql-driver.jar"
  configure_extra_classpath >&2
  echo "JBOSS_KIE_EXTRA_CLASSPATH is ${JBOSS_KIE_EXTRA_CLASSPATH}" >&2
  echo "Expected is ${expected}" >&2
  [[ $JBOSS_KIE_EXTRA_CLASSPATH == "${expected}" ]]
}

@test "check if extra classpath is set correctly for multiple entries" {
  local expected

  JBOSS_KIE_EXTRA_CLASSPATH="mysql-driver.jar, oracledb-driver.jar"
  expected="-Dthorntail.classpath=mysql-driver.jar -Dthorntail.classpath=oracledb-driver.jar"
  configure_extra_classpath >&2
  echo "JBOSS_KIE_EXTRA_CLASSPATH is ${JBOSS_KIE_EXTRA_CLASSPATH}" >&2
  echo "Expected is ${expected}" >&2
  [[ $JBOSS_KIE_EXTRA_CLASSPATH == "${expected}" ]]
}

@test "check if extra classpath is empty when defined but empty" {
  local expected

  JBOSS_KIE_EXTRA_CLASSPATH=""
  expected=""
  configure_extra_classpath >&2
  echo "JBOSS_KIE_EXTRA_CLASSPATH is ${JBOSS_KIE_EXTRA_CLASSPATH}" >&2
  echo "Expected is ${expected}" >&2
  [[ $JBOSS_KIE_EXTRA_CLASSPATH == "${expected}" ]]
}

@test "check if extra classpath is empty when undefined" {
  local expected

  [[ -z $JBOSS_KIE_EXTRA_CLASSPATH ]]
  expected=""
  configure_extra_classpath >&2
  echo "JBOSS_KIE_EXTRA_CLASSPATH is ${JBOSS_KIE_EXTRA_CLASSPATH}" >&2
  echo "Expected is ${expected}" >&2
  [[ $JBOSS_KIE_EXTRA_CLASSPATH == "${expected}" ]]
}

@test "check if extra config is empty when undefined" {
  local expected

  [[ -z $JBOSS_KIE_EXTRA_CONFIG ]]
  expected=""
  configure_extra_classpath >&2
  echo "JBOSS_KIE_EXTRA_CONFIG is ${JBOSS_KIE_EXTRA_CONFIG}" >&2
  echo "Expected is ${expected}" >&2
  [[ $JBOSS_KIE_EXTRA_CONFIG == "${expected}" ]]
}

@test "check if extra config is empty when defined but empty" {
  local expected

  JBOSS_KIE_EXTRA_CONFIG=""
  expected=""
  configure_extra_classpath >&2
  echo "JBOSS_KIE_EXTRA_CONFIG is ${JBOSS_KIE_EXTRA_CONFIG}" >&2
  echo "Expected is ${expected}" >&2
  [[ $JBOSS_KIE_EXTRA_CONFIG == "${expected}" ]]
}

@test "check if extra config is set" {
  local expected

  JBOSS_KIE_EXTRA_CONFIG="./config-extra/configuration.yml"
  expected="-s./config-extra/configuration.yml"
  configure_extra_config >&2
  echo "JBOSS_KIE_EXTRA_CONFIG is ${JBOSS_KIE_EXTRA_CONFIG}" >&2
  echo "Expected is ${expected}" >&2
  [[ $JBOSS_KIE_EXTRA_CONFIG == "${expected}" ]]
}

@test "check if roles file is populated with default values" {
  configure_users
  local roles=$(head -n 1 $CONFIG_DIR/application-roles.properties)
  expected="admin=admin"
  echo "roles first line is ${roles}"
  echo "Expected is ${expected}" >&2
  [[ ${roles} == "${expected}" ]]
}

@test "check if roles file is populated with provided values" {
  JBOSS_KIE_ADMIN_USER=foo
  configure_users
  local roles=$(head -n 1 $CONFIG_DIR/application-roles.properties)
  expected="foo=admin"
  echo "roles first line is ${roles}"
  echo "Expected is ${expected}" >&2
  [[ ${roles} == "${expected}" ]]
}

@test "check if users file is populated with default values" {
  configure_users
  local users=$(head -n 1 $CONFIG_DIR/application-users.properties)
  expected="^admin=[a-zA-Z0-9_\!]{8}$"
  echo "users first line is ${users}"
  echo "Expected is ${expected}" >&2
  [[ ${users} =~ ${expected} ]]
}

@test "check if users file is populated with provided values" {
  JBOSS_KIE_ADMIN_USER=foo
  JBOSS_KIE_ADMIN_PWD=test
  configure_users
  local users=$(head -n 1 $CONFIG_DIR/application-users.properties)
  expected="foo=test"
  echo "users first line is ${users}"
  echo "Expected is ${expected}" >&2
  [[ ${users} == "${expected}" ]]
}
