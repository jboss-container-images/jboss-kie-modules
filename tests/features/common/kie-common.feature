@rhdm-7/rhdm71-kieserver-openshift  @rhpam-7/rhpam71-kieserver-openshift @rhdm-7/rhdm71-decisioncentral-openshift @rhpam-7/rhpam71-businesscentral-openshift @rhpam-7/rhpam71-businesscentral-monitoring-openshift
Feature: RHPAM and RHDM common tests

  Scenario: Configure kie-workbench to use LDAP authentication
    When container is started with env
      | variable      | value    |
      | AUTH_LDAP_URL | test_url |
    Then container log should contain AUTH_LDAP_URL is set to test_url. Added LdapExtended login-module
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <login-module code="LdapExtended"

  Scenario: Configure kie-workbench to use LDAP authentication
    When container is started with env
      | variable                                      | value                        |
      | AUTH_LDAP_URL                                 | test_url                     |
      | AUTH_LDAP_BIND_DN                             | cn=Manager,dc=example,dc=com |
      | AUTH_LDAP_BIND_CREDENTIAL                     | admin                        |
      | AUTH_LDAP_BASE_CTX_DN                         | ou=Users,dc=example,dc=com   |
      | AUTH_LDAP_BASE_FILTER                         | (uid={0})                    |
      | AUTH_LDAP_ROLE_ATTRIBUTE_ID                   | cn                           |
      | AUTH_LDAP_ROLES_CTX_DN                        | ou=Roles,dc=example,dc=com   |
      | AUTH_LDAP_ROLE_FILTER                         | (member={1})                 |
      | AUTH_LDAP_ALLOW_EMPTY_PASSWORDS               | true                         |
      | AUTH_LDAP_DEFAULT_ROLE                        | test                         |
      | AUTH_LDAP_DISTINGUISHED_NAME_ATTRIBUTE        | name1                        |
      | AUTH_LDAP_JAAS_SECURITY_DOMAIN                | other                        |
      | AUTH_LDAP_PARSE_ROLE_NAME_FROM_DN             | true                         |
      | AUTH_LDAP_PARSE_USERNAME                      | true                         |
      | AUTH_LDAP_REFERRAL_USER_ATTRIBUTE_ID_TO_CHECK | uid                          |
      | AUTH_LDAP_ROLE_ATTRIBUTE_IS_DN                | true                         |
      | AUTH_LDAP_ROLE_NAME_ATTRIBUTE_ID              | roleId                       |
      | AUTH_LDAP_ROLE_RECURSION                      | true                         |
      | AUTH_LDAP_SEARCH_SCOPE                        | SUBTREE                      |
      | AUTH_LDAP_SEARCH_TIME_LIMIT                   | 100                          |
      | AUTH_LDAP_USERNAME_BEGIN_STRING               | USER                         |
      | AUTH_LDAP_USERNAME_END_STRING                 | ENDUSER                      |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <login-module code="RealmDirect" flag="optional">
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <login-module code="LdapExtended" flag="required">
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="java.naming.provider.url" value="test_url"/>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="bindDN" value="cn=Manager,dc=example,dc=com"/>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="bindCredential" value="admin"/>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="baseCtxDN" value="ou=Users,dc=example,dc=com"/>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="baseFilter" value="(uid={0})"/>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="rolesCtxDN" value="ou=Roles,dc=example,dc=com"/>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="roleFilter" value="(member={1})"/>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="roleAttributeID" value="cn"/>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="allowEmptyPasswords" value="true"/>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="defaultRole" value="test"/>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="distinguishedNameAttribute" value="name1"/>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="jaasSecurityDomain" value="other"/>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="parseRoleNameFromDN" value="true"/>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="parseUsername" value="true"/>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="referralUserAttributeIDToCheck" value="uid"/>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="roleAttributeIsDN" value="true"/>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="roleNameAttributeID" value="roleId"/>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="roleRecursion" value="true"/>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="searchScope" value="SUBTREE"/>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="searchTimeLimit" value="100"/>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="usernameBeginString" value="USER"/>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="usernameEndString" value="ENDUSER"/>

  Scenario: test KIE_MBEANS configuration
    When container is started with env
      | variable   | value |
      | KIE_MBEANS | false |
    Then container log should contain -Dkie.mbeans=disabled -Dkie.scanner.mbeans=disabled
