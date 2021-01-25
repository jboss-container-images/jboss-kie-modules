#!/usr/bin/env bats

load jboss-kie-wildfly-common

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
mkdir -p $JBOSS_HOME/standalone/configuration
mkdir -p $JBOSS_HOME/bin/launch

export CONFIG_FILE=$JBOSS_HOME/standalone/configuration/standalone-openshift.xml

source $BATS_TEST_DIRNAME/../../added/launch/jboss-kie-wildfly-security-login-modules.sh

setup() {
  cp $BATS_TEST_DIRNAME/resources/standalone-openshift.xml $CONFIG_FILE
  run unset_kie_security_auth_env
}

@test "do not replace placeholder when URL is not provided" {
    AUTH_LDAP_ALLOW_EMPTY_PWD="test AUTH_LDAP_ALLOW_EMPTY_PWD"
    AUTH_LDAP_BASE_DN="test AUTH_LDAP_BASE_DN"
    AUTH_LDAP_BASE_FILTER="test AUTH_LDAP_BASE_FILTER"
    AUTH_LDAP_BIND_DN="test AUTH_LDAP_BIND_DN"
    AUTH_LDAP_BIND_PWD="test AUTH_LDAP_BIND_PWD"
    AUTH_LDAP_ROLE_ATTR_ID="test AUTH_LDAP_ROLE_ATTR_ID"
    AUTH_LDAP_ROLE_ATTR_IS_DN="test AUTH_LDAP_ROLE_ATTR_IS_DN"
    AUTH_LDAP_ROLE_DN="test AUTH_LDAP_ROLE_DN"
    AUTH_LDAP_ROLE_FILTER="test AUTH_LDAP_ROLE_FILTER"
    AUTH_LDAP_ROLE_NAME_ATTR_ID="test AUTH_LDAP_ROLE_NAME_ATTR_ID"
    AUTH_LDAP_SEARCH_SCOPE="test AUTH_LDAP_SEARCH_SCOPE"

    run configure_ldap_login_module

    [ "$output" = "[INFO]AUTH_LDAP_URL not set. Skipping LDAP integration..." ]
    [ "$status" -eq 0 ]
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-openshift-untouched.xml
}

@test "replace placeholder by minimum xml content when URL is provided" {
    AUTH_LDAP_URL="test_url"

    run configure_ldap_login_module

    [ "$output" = "[INFO]AUTH_LDAP_URL is set to test_url. Added LdapExtended login-module" ]
    [ "$status" -eq 0 ]
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-openshift-ldap-url.xml
}

@test "replace placeholder by all LDAP values when provided" {
    AUTH_LDAP_ALLOW_EMPTY_PASSWORDS="test AUTH_LDAP_ALLOW_EMPTY_PASSWORDS"
    AUTH_LDAP_BASE_CTX_DN="test AUTH_LDAP_BASE_CTX_DN"
    AUTH_LDAP_BASE_FILTER="test AUTH_LDAP_BASE_FILTER"
    AUTH_LDAP_BIND_CREDENTIAL="test AUTH_LDAP_BIND_CREDENTIAL"
    AUTH_LDAP_BIND_DN="test AUTH_LDAP_BIND_DN"
    AUTH_LDAP_DEFAULT_ROLE="test AUTH_LDAP_DEFAULT_ROLE"
    AUTH_LDAP_DISTINGUISHED_NAME_ATTRIBUTE="test AUTH_LDAP_DISTINGUISHED_NAME_ATTRIBUTE"
    AUTH_LDAP_JAAS_SECURITY_DOMAIN="test AUTH_LDAP_JAAS_SECURITY_DOMAIN"
    AUTH_LDAP_LOGIN_MODULE="test AUTH_LDAP_LOGIN_MODULE"
    AUTH_LDAP_PARSE_ROLE_NAME_FROM_DN="test AUTH_LDAP_PARSE_ROLE_NAME_FROM_DN"
    AUTH_LDAP_PARSE_USERNAME="test AUTH_LDAP_PARSE_USERNAME"
    AUTH_LDAP_REFERRAL_USER_ATTRIBUTE_ID_TO_CHECK="test AUTH_LDAP_REFERRAL_USER_ATTRIBUTE_ID_TO_CHECK"
    AUTH_LDAP_ROLE_ATTRIBUTE_ID="test AUTH_LDAP_ROLE_ATTRIBUTE_ID"
    AUTH_LDAP_ROLE_ATTRIBUTE_IS_DN="test AUTH_LDAP_ROLE_ATTRIBUTE_IS_DN"
    AUTH_LDAP_ROLE_FILTER="test AUTH_LDAP_ROLE_FILTER"
    AUTH_LDAP_ROLE_NAME_ATTRIBUTE_ID="test AUTH_LDAP_ROLE_NAME_ATTRIBUTE_ID"
    AUTH_LDAP_ROLE_RECURSION="test AUTH_LDAP_ROLE_RECURSION"
    AUTH_LDAP_ROLES_CTX_DN="test AUTH_LDAP_ROLES_CTX_DN"
    AUTH_LDAP_SEARCH_SCOPE="test AUTH_LDAP_SEARCH_SCOPE"
    AUTH_LDAP_SEARCH_TIME_LIMIT="test AUTH_LDAP_SEARCH_TIME_LIMIT"
    AUTH_LDAP_URL="test AUTH_LDAP_URL"
    AUTH_LDAP_USERNAME_BEGIN_STRING="test AUTH_LDAP_USERNAME_BEGIN_STRING"
    AUTH_LDAP_USERNAME_END_STRING="test AUTH_LDAP_USERNAME_END_STRING"

    run configure_ldap_login_module

    [ "$output" = "[INFO]AUTH_LDAP_URL is set to test AUTH_LDAP_URL. Added LdapExtended login-module" ]
    [ "$status" -eq 0 ]
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-openshift-ldap-all.xml
}

@test "ldap baseFilter is correctly configured when & and | is present" {
    AUTH_LDAP_URL="test_url"
    AUTH_LDAP_BASE_FILTER="(&(mail={0}))(|(objectclass=dbperson)(objectclass=inetOrgPerson)))"

    run configure_ldap_login_module
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-openshift-ldap-baseFilter.xml
}