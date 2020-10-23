#!/usr/bin/env bats

load jboss-kie-wildfly-common

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
mkdir -p $JBOSS_HOME/standalone/configuration
mkdir -p $JBOSS_HOME/bin/launch

cp $BATS_TEST_DIRNAME/../../../tests/bats/common/launch-common.sh $JBOSS_HOME/bin/launch
touch $JBOSS_HOME/bin/launch/logging.sh

export CONFIG_FILE=$JBOSS_HOME/standalone/configuration/standalone-openshift.xml

source $BATS_TEST_DIRNAME/../../added/launch/jboss-kie-wildfly-security.sh

setup() {
  cp $BATS_TEST_DIRNAME/resources/application-properties.xml $CONFIG_FILE
  run unset_kie_security_env
}

@test "leave application users and roles alone when properties are not provided" {
    run set_application_users_config
    [ "$status" -eq 0 ]
    run set_application_roles_config
    [ "$status" -eq 0 ]

    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/resources/application-properties.xml
}

@test "replace application users and roles when properties are provided" {
    APPLICATION_USERS_PROPERTIES="${BATS_TMPDIR}/opt/kie/data/configuration/application-users.properties"
    APPLICATION_ROLES_PROPERTIES="${BATS_TMPDIR}/opt/kie/data/configuration/application-roles.properties"

    run set_application_users_config
    [ "$status" -eq 0 ]
    run set_application_roles_config
    [ "$status" -eq 0 ]

    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/application-properties-replaced.xml

    grep '^\#\$REALM_NAME=ApplicationRealm\$' "${APPLICATION_USERS_PROPERTIES}" > /dev/null 2>&1
    [ "$status" -eq 0 ]
}

@test "check if pwd password is set combination one" {
    KIE_ADMIN_PWD=passw${0}rd
    run get_kie_admin_pwd
    [[ ${lines[0]} == "passw${0}rd" ]]
    unset KIE_ADMIN_PWD
}

@test "check if pwd password is set combination two" {
    KIE_ADMIN_PWD=$0passwrd
    run get_kie_admin_pwd
    [[ ${lines[0]} == "$0passwrd" ]]
    unset KIE_ADMIN_PWD
}

@test "check if pwd password is set combination three" {
    KIE_ADMIN_PWD=${0}passwrd
    run get_kie_admin_pwd
    [[ ${lines[0]} == "${0}passwrd" ]]
    unset KIE_ADMIN_PWD
}

@test "check if pwd password is set combination four" {
    KIE_ADMIN_PWD=passw${0}rd
    run get_kie_admin_pwd
    [[ ${lines[0]} == "passw${0}rd" ]]
    unset KIE_ADMIN_PWD
}

@test "check if pwd password is set combination five" {
    KIE_ADMIN_PWD=\'$0\'passwrd
    run get_kie_admin_pwd
    [[ ${lines[0]} == "'$0'passwrd" ]]
    unset KIE_ADMIN_PWD
}

@test "check if pwd password is set combination six" {
    KIE_ADMIN_PWD=\'${0}\'passwrd
    run get_kie_admin_pwd
    [[ ${lines[0]} == "'${0}'passwrd" ]]
    unset KIE_ADMIN_PWD
}