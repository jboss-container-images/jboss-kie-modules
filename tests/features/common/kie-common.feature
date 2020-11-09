@rhdm-7/rhdm-kieserver-rhel8  @rhpam-7/rhpam-kieserver-rhel8 @rhdm-7/rhdm-decisioncentral-rhel8 @rhpam-7/rhpam-businesscentral-rhel8 @rhpam-7/rhpam-businesscentral-monitoring-rhel8 @rhpam-7/rhpam-dashbuilder-rhel8 @rhpam-7/rhpam-controller-rhel8 @rhdm-7/rhdm-controller-rhel8
Feature: RHPAM and RHDM common tests

  Scenario: Configure kie-workbench to use LDAP authentication
    When container is started with env
      | variable      | value    |
      | AUTH_LDAP_URL | test_url |
    Then container log should contain AUTH_LDAP_URL is set to test_url. Added LdapExtended login-module
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <login-module code="LdapExtended"

  Scenario: Configure images to use LDAP authentication
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

  Scenario: Check if eap users are not being created if SSO is configured with no users env
    When container is started with env
      | variable                   | value         |
      | SSO_URL                    | http://url    |
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain adminUser
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain adminUser
     And container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain Make sure to configure KIE_ADMIN_USER user to access the application with the roles kie-server,rest-all,admin,kiemgmt,Administrators,user

  Scenario: KIECLOUD-274 Prepare PAM/DM images to accept the logger category configuration
    When container is started with env
      | variable          | value                                            |
      | LOGGER_CATEGORIES | com.my.package:TRACE, com.my.other.package:TRACE |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <logger category="com.my.package">
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <logger category="com.my.other.package">
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <level name="TRACE"/>

  # https://issues.jboss.org/browse/RHPAM-891
  # https://issues.jboss.org/browse/RHPAM-1135
  Scenario: Check custom users are properly configured
    When container is started with env
      | variable                   | value         |
      | KIE_ADMIN_USER             | customAdm     |
      | KIE_ADMIN_PWD              | custom" Adm!0 |
    Then file /opt/eap/standalone/configuration/application-users.properties should contain customAdm=a4d41e50a4ae17a50c1ceabe21e41a80
     And file /opt/eap/standalone/configuration/application-roles.properties should contain customAdm=kie-server,rest-all,admin,kiemgmt,Administrators,user

  Scenario: Check custom users with custom roles are properly configured
    When container is started with env
      | variable                   | value         |
      | KIE_ADMIN_USER             | customAdm     |
      | KIE_ADMIN_PWD              | custom" Adm!0 |
      | KIE_ADMIN_ROLES            | role1,admin2  |
    Then file /opt/eap/standalone/configuration/application-users.properties should contain customAdm=a4d41e50a4ae17a50c1ceabe21e41a80
    And file /opt/eap/standalone/configuration/application-roles.properties should contain customAdm=role1,admin2

  # https://issues.jboss.org/browse/RHPAM-891
  Scenario: Check default users are properly configured
    When container is ready
    Then file /opt/eap/standalone/configuration/application-users.properties should contain adminUser=de3155e1927c6976555925dec24a53ac
    And file /opt/eap/standalone/configuration/application-roles.properties should contain adminUser=kie-server,rest-all,admin,kiemgmt,Administrators
