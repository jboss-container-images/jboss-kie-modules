#!/usr/bin/env bats

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
export LAUNCH_DIR=$JBOSS_HOME/bin/launch
export CONFIG_DIR=$JBOSS_HOME/quarkus-app/config
mkdir -p $LAUNCH_DIR ${CONFIG_DIR} $JBOSS_HOME/quarkus-app/lib/deployment ${JBOSS_HOME}/extra-classpath/

cp $BATS_TEST_DIRNAME/../../../tests/bats/common/launch-common.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../tests/bats/common/logging.bash $JBOSS_HOME/bin/launch/logging.sh
cp $BATS_TEST_DIRNAME/../../../jboss-kie-process-migration/added/launch/jboss-kie-pim-common.sh $JBOSS_HOME/bin/launch/jboss-kie-pim-common.sh
cp $BATS_TEST_DIRNAME/../../../jboss-kie-common/added/launch/jboss-kie-common.sh $JBOSS_HOME/bin/launch/jboss-kie-common.sh

#imports
source $BATS_TEST_DIRNAME/../../added/launch/jboss-kie-process-migration.sh

setup() {
    cp -rv $BATS_TEST_DIRNAME/../../added/configuration ${CONFIG_DIR}
}

teardown() {
    rm -rf $JBOSS_HOME
}

@test "check if extra classpath is set correctly" {
    touch ${JBOSS_HOME}/extra-classpath/mysql-driver.jar
    JBOSS_KIE_EXTRA_CLASSPATH="${JBOSS_HOME}/extra-classpath/mysql-driver.jar"
    configure_extra_classpath
    [ -f $JBOSS_HOME/quarkus-app/lib/deployment/mysql-driver.jar ]
}

@test "check if extra classpath is set correctly for multiple entries" {
    touch ${JBOSS_HOME}/extra-classpath/mysql-driver.jar
    touch ${JBOSS_HOME}/extra-classpath/other.jar
    JBOSS_KIE_EXTRA_CLASSPATH="${JBOSS_HOME}/extra-classpath/mysql-driver.jar, ${JBOSS_HOME}/extra-classpath/other.jar"
    configure_extra_classpath
    [ -f $JBOSS_HOME/quarkus-app/lib/deployment/mysql-driver.jar ]
    [ -f $JBOSS_HOME/quarkus-app/lib/deployment/other.jar ]
}

@test "check if user files is not populated" {
    run configure_admin_user
    echo "Expected is ${lines[0]}"
    [ "${lines[0]}" = "[WARN]No external configuration or user added, please set one of them." ]
    [ ! -f $CONFIG_DIR/application-users.properties ]
    [ ! -f $CONFIG_DIR/application-roles.properties ]
}

@test "check if user files is not populated when password is missing" {
    JBOSS_KIE_ADMIN_USER=foo
    run configure_admin_user
    echo "Expected is ${lines[0]}"
    [ "${lines[0]}" = "[WARN]No external configuration or user added, please set one of them." ]
    [ ! -f $CONFIG_DIR/application-users.properties ]
    [ ! -f $CONFIG_DIR/application-roles.properties ]
}

@test "check if user files file is not populated when user is missing" {
    JBOSS_KIE_ADMIN_PWD=foo
    run configure_admin_user
    echo "Expected is ${lines[0]}"
    [ "${lines[0]}" = "[WARN]No external configuration or user added, please set one of them." ]
    [ ! -f $CONFIG_DIR/application-users.properties ]
    [ ! -f $CONFIG_DIR/application-roles.properties ]
}

@test "check if user files are populated when credentials are provided" {
    JBOSS_KIE_ADMIN_USER=foo
    JBOSS_KIE_ADMIN_PWD=bar
    echo "pim:
        auth-method: file
      quarkus:
        security:
          users:
            file:
              enabled: true
              plain-text: true
              users: /opt/ibm-bamoe-process-migration/quarkus-app/config/application-users.properties
              roles: /opt/ibm-bamoe-process-migration/quarkus-app/config/application-roles.properties" > $CONFIG_DIR/default-auth.yaml

    run configure_admin_user

    expected_user=$(head -n 1 $CONFIG_DIR/application-users.properties)
    expected_role=$(head -n 1 $CONFIG_DIR/application-roles.properties)
    echo "Expected lines 0 is ${lines[0]}"
    echo "Expected lines 1 is ${lines[1]}"
    echo "Expected user: $expected_user"
    echo "Expected role: $expected_role"
    [ "${lines[0]}" = "renamed '/tmp/jboss_home/quarkus-app/config/default-auth.yaml' -> '/tmp/jboss_home/quarkus-app/config/application.yaml'" ]
    [ "${lines[1]}" = "[INFO]Basic security auth added for user foo, it is strongly recommended to provide your own configuration file using md5 hash to hide the password." ]
    [ -f $CONFIG_DIR/application-users.properties ]
    [ -f $CONFIG_DIR/application-roles.properties ]
    [ -f $CONFIG_DIR/application.yaml ]
    [ "${expected_user}" = "foo=bar" ]
    [ "${expected_role}" = "foo=admin" ]
}

