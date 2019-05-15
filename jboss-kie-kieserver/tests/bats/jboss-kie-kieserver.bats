#!/usr/bin/env bats

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
mkdir -p $JBOSS_HOME/bin/launch

cp $BATS_TEST_DIRNAME/../../../tests/bats/common/launch-common.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../tests/bats/common/logging.bash $JBOSS_HOME/bin/launch/logging.sh
cp $BATS_TEST_DIRNAME/../../../jboss-kie-wildfly-common/added/launch/jboss-kie-wildfly-security-login-modules.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../jboss-kie-wildfly-common/added/launch/jboss-kie-wildfly-common.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../jboss-kie-wildfly-common/added/launch/jboss-kie-wildfly-security.sh $JBOSS_HOME/bin/launch

# mocking
touch $JBOSS_HOME/bin/launch/datasource-common.sh

#imports
source $BATS_TEST_DIRNAME/../../added/launch/jboss-kie-kieserver.sh

teardown() {
    rm -rf $JBOSS_HOME
}

@test "test if the EJB_TIMER datasource has been auto-configured" { 
  local expected_timer_service="EJB_TIMER"
  local expected_datasources="EJB_TIMER,RHPAM"
  export DATASOURCES="RHPAM"
  export RHPAM_XA_CONNECTION_PROPERTY_URL="jdbc:h2:/deployments/data/h2/rhpam;AUTO_SERVER=TRUE"
  configure_EJB_Timer_datasource >&2
  echo "Expected EJB_TIMER url is ${EJB_TIMER_XA_CONNECTION_PROPERTY_URL}" >&2 
  echo "Expected DATASOURCES is ${DATASOURCES}" >&2 
  [ "${TIMER_SERVICE_DATA_STORE^^}" = "${expected_timer_service}" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_URL}" = "${RHPAM_XA_CONNECTION_PROPERTY_URL}" ]
  [ "${DATASOURCES}" = "${expected_datasources}" ]
}