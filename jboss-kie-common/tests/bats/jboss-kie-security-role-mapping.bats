#!/usr/bin/env bats

load jboss-kie-common

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
mkdir -p $JBOSS_HOME/standalone/configuration
mkdir -p $JBOSS_HOME/bin/launch

export CONFIG_FILE=$JBOSS_HOME/standalone/configuration/standalone-openshift.xml

source $BATS_TEST_DIRNAME/../../added/launch/jboss-kie-security-login-modules.sh

setup() {
  cp $BATS_TEST_DIRNAME/resources/standalone-openshift.xml $CONFIG_FILE
  run unset_kie_security_auth_env
}

@test "do not replace placeholder when ROLES_PROPERTIES is not provided" {
    run configure_role_mapper_login_module

    [ "$output" = "[INFO]AUTH_ROLE_MAPPER_ROLES_PROPERTIES not set. Skipping RoleMapping login module." ]
    [ "$status" -eq 0 ]
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-openshift-untouched.xml
}

@test "add login-module" {
    AUTH_ROLE_MAPPER_ROLES_PROPERTIES="props/rolemapping.properties"

    run configure_role_mapper_login_module

    [ "${lines[0]}" = "[INFO]AUTH_ROLE_MAPPER_ROLES_PROPERTIES is set to props/rolemapping.properties" ]
    [ "$status" -eq 0 ]
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-openshift-role-mapper.xml
}


@test "add login-module with replaceRole" {
    AUTH_ROLE_MAPPER_ROLES_PROPERTIES="props/rolemapping.properties"
    AUTH_ROLE_MAPPER_REPLACE_ROLE="true"

    run configure_role_mapper_login_module

    [ "${lines[0]}" = "[INFO]AUTH_ROLE_MAPPER_ROLES_PROPERTIES is set to props/rolemapping.properties" ]
    [ "$status" -eq 0 ]
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-openshift-role-mapper-replaceRole.xml
}
