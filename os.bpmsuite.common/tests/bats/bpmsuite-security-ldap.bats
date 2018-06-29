#!/usr/bin/env bats

load bpmsuite-common

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
mkdir -p $JBOSS_HOME/standalone/configuration
mkdir -p $JBOSS_HOME/bin/launch

export CONFIG_FILE=$JBOSS_HOME/standalone/configuration/standalone-openshift.xml

source $BATS_TEST_DIRNAME/../../added/launch/bpmsuite-security-ldap.sh

setup() {
  cp $BATS_TEST_DIRNAME/resources/standalone-openshift.xml $CONFIG_FILE
  run unset_kie_security_ldap_env
}

@test "do not replace placeholder when URL is not provided" {
    KIE_AUTH_LDAP_ALLOW_EMPTY_PWD="test KIE_AUTH_LDAP_ALLOW_EMPTY_PWD"
    KIE_AUTH_LDAP_BASE_DN="test KIE_AUTH_LDAP_BASE_DN"
    KIE_AUTH_LDAP_BASE_FILTER="test KIE_AUTH_LDAP_BASE_FILTER"
    KIE_AUTH_LDAP_BIND_DN="test KIE_AUTH_LDAP_BIND_DN"
    KIE_AUTH_LDAP_BIND_PWD="test KIE_AUTH_LDAP_BIND_PWD"
    KIE_AUTH_LDAP_ROLE_ATTR_ID="test KIE_AUTH_LDAP_ROLE_ATTR_ID"
    KIE_AUTH_LDAP_ROLE_ATTR_IS_DN="test KIE_AUTH_LDAP_ROLE_ATTR_IS_DN"
    KIE_AUTH_LDAP_ROLE_DN="test KIE_AUTH_LDAP_ROLE_DN"
    KIE_AUTH_LDAP_ROLE_FILTER="test KIE_AUTH_LDAP_ROLE_FILTER"
    KIE_AUTH_LDAP_ROLE_NAME_ATTR_ID="test KIE_AUTH_LDAP_ROLE_NAME_ATTR_ID"
    KIE_AUTH_LDAP_SEARCH_SCOPE="test KIE_AUTH_LDAP_SEARCH_SCOPE"

    run configure_ldap_security_domain

    [ "$output" = "[INFO]KIE_AUTH_LDAP_URL not set. Skipping LDAP integration..." ]
    [ "$status" -eq 0 ]
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-openshift-untouched.xml
}

@test "replace placeholder by minimum xml content when URL is provided" {
    KIE_AUTH_LDAP_URL="test_url"

    run configure_ldap_security_domain

    [ "$output" = "[INFO]KIE_AUTH_LDAP_URL is set to test_url. Added LdapExtended login-module" ]
    [ "$status" -eq 0 ]
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-openshift-ldap-url.xml
}

@test "replace placeholder by all LDAP values when provided" {
    KIE_AUTH_LDAP_ALLOW_EMPTY_PASSWORDS="test KIE_AUTH_LDAP_ALLOW_EMPTY_PASSWORDS"
    KIE_AUTH_LDAP_BASE_CTX_DN="test KIE_AUTH_LDAP_BASE_CTX_DN"
    KIE_AUTH_LDAP_BASE_FILTER="test KIE_AUTH_LDAP_BASE_FILTER"
    KIE_AUTH_LDAP_BIND_CREDENTIAL="test KIE_AUTH_LDAP_BIND_CREDENTIAL"
    KIE_AUTH_LDAP_BIND_DN="test KIE_AUTH_LDAP_BIND_DN"
    KIE_AUTH_LDAP_DEFAULT_ROLE="test KIE_AUTH_LDAP_DEFAULT_ROLE"
    KIE_AUTH_LDAP_DISTINGUISHED_NAME_ATTRIBUTE="test KIE_AUTH_LDAP_DISTINGUISHED_NAME_ATTRIBUTE"
    KIE_AUTH_LDAP_JAAS_SECURITY_DOMAIN="test KIE_AUTH_LDAP_JAAS_SECURITY_DOMAIN"
    KIE_AUTH_LDAP_PARSE_ROLE_NAME_FROM_DN="test KIE_AUTH_LDAP_PARSE_ROLE_NAME_FROM_DN"
    KIE_AUTH_LDAP_PARSE_USERNAME="test KIE_AUTH_LDAP_PARSE_USERNAME"
    KIE_AUTH_LDAP_REFERRAL_USER_ATTRIBUTE_ID_TO_CHECK="test KIE_AUTH_LDAP_REFERRAL_USER_ATTRIBUTE_ID_TO_CHECK"
    KIE_AUTH_LDAP_ROLE_ATTRIBUTE_ID="test KIE_AUTH_LDAP_ROLE_ATTRIBUTE_ID"
    KIE_AUTH_LDAP_ROLE_ATTRIBUTE_IS_DN="test KIE_AUTH_LDAP_ROLE_ATTRIBUTE_IS_DN"
    KIE_AUTH_LDAP_ROLE_FILTER="test KIE_AUTH_LDAP_ROLE_FILTER"
    KIE_AUTH_LDAP_ROLE_NAME_ATTRIBUTE_ID="test KIE_AUTH_LDAP_ROLE_NAME_ATTRIBUTE_ID"
    KIE_AUTH_LDAP_ROLE_RECURSION="test KIE_AUTH_LDAP_ROLE_RECURSION"
    KIE_AUTH_LDAP_ROLES_CTX_DN="test KIE_AUTH_LDAP_ROLES_CTX_DN"
    KIE_AUTH_LDAP_SEARCH_SCOPE="test KIE_AUTH_LDAP_SEARCH_SCOPE"
    KIE_AUTH_LDAP_SEARCH_TIME_LIMIT="test KIE_AUTH_LDAP_SEARCH_TIME_LIMIT"
    KIE_AUTH_LDAP_URL="test KIE_AUTH_LDAP_URL"
    KIE_AUTH_LDAP_USERNAME_BEGIN_STRING="test KIE_AUTH_LDAP_USERNAME_BEGIN_STRING"
    KIE_AUTH_LDAP_USERNAME_END_STRING="test KIE_AUTH_LDAP_USERNAME_END_STRING"

    run configure_ldap_security_domain

    [ "$output" = "[INFO]KIE_AUTH_LDAP_URL is set to test KIE_AUTH_LDAP_URL. Added LdapExtended login-module" ]
    [ "$status" -eq 0 ]
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-openshift-ldap-all.xml
}
