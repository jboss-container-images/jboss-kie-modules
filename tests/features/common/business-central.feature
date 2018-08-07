@rhdm-7/rhdm71-decisioncentral-openshift @rhpam-7/rhpam71-businesscentral-openshift @rhpam-7/rhpam71-businesscentral-monitoring-openshift
Feature: Decision/Business Central common features

  Scenario: Configure business-central to use LDAP authentication
    When container is started with env
      | variable      | value     |
      | AUTH_LDAP_URL | test_url  |
    Then container log should contain AUTH_LDAP_URL is set to test_url. Added LdapExtended login-module
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <login-module code="LdapExtended"

  Scenario: Configure business-central to use LDAP authentication
    When container is started with env
      | variable                    | value                         |
      | AUTH_LDAP_URL               | test_url                      |
      | AUTH_LDAP_BIND_DN           | cn=Manager,dc=example,dc=com  |
      | AUTH_LDAP_BIND_CREDENTIAL   | admin                         |
      | AUTH_LDAP_BASE_CTX_DN       | ou=Users,dc=example,dc=com    |
      | AUTH_LDAP_BASE_FILTER       | (uid={0})                     |
      | AUTH_LDAP_ROLE_ATTRIBUTE_ID | cn                            |
      | AUTH_LDAP_ROLES_CTX_DN      | ou=Roles,dc=example,dc=com    |
      | AUTH_LDAP_ROLE_FILTER       | (member={1})                  |
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
