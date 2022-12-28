@rhpam-7/rhpam-kieserver-rhel8
@rhpam-7/rhpam-businesscentral-rhel8
@rhpam-7/rhpam-businesscentral-monitoring-rhel8
@rhpam-7/rhpam-dashbuilder-rhel8
@rhpam-7/rhpam-controller-rhel8
Feature: KIE Security configuration common tests

  Scenario: Configure container to use LDAP authentication
    When container is started with env
      | variable                      | value                        |
      | AUTH_LDAP_URL                 | test_url                     |
      | AUTH_LDAP_BASE_FILTER         | uid                          |
      | AUTH_LDAP_BASE_CTX_DN         | ou=Users,dc=example,dc=com   |
      | AUTH_LDAP_ROLE_ATTRIBUTE_ID   | cn                           |
      | AUTH_LDAP_ROLES_CTX_DN        | ou=Roles,dc=example,dc=com   |
      | AUTH_LDAP_ROLE_FILTER         | (member={1})                 |
    Then container log should contain AUTH_LDAP_URL is set to [test_url], setting up LDAP authentication with elytron...
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <dir-context name="KIELdapDC" url="test_url"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <identity-mapping rdn-identifier="uid" search-base-dn="ou=Users,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <attribute from="cn" to="Roles" filter="(member={1})" filter-base-dn="ou=Roles,dc=example,dc=com"/>

  Scenario: Configure images to use LDAP authentication with default role
    When container is started with env
      | variable                                      | value                        |
      | AUTH_LDAP_URL                                 | test_url                     |
      | AUTH_LDAP_BIND_DN                             | cn=Manager,dc=example,dc=com |
      | AUTH_LDAP_BIND_CREDENTIAL                     | admin                        |
      | AUTH_LDAP_BASE_CTX_DN                         | ou=Users,dc=example,dc=com   |
      | AUTH_LDAP_BASE_FILTER                         | uid                          |
      | AUTH_LDAP_ROLE_ATTRIBUTE_ID                   | cn                           |
      | AUTH_LDAP_ROLES_CTX_DN                        | ou=Roles,dc=example,dc=com   |
      | AUTH_LDAP_ROLE_FILTER                         | (member={1})                 |
      | AUTH_LDAP_DEFAULT_ROLE                        | test                         |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <dir-context name="KIELdapDC" url="test_url" principal="cn=Manager,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <credential-reference clear-text="admin"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <attribute from="cn" to="Roles" filter="(member={1})" filter-base-dn="ou=Roles,dc=example,dc=com"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <ldap-realm name="KIELdapRealm" dir-context="KIELdapDC">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <identity-mapping rdn-identifier="uid" search-base-dn="ou=Users,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security-domain name="KIELdapSecurityDomain" default-realm="KIELdapRealm" permission-mapper="default-permission-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <realm name="KIELdapRealm" role-decoder="from-roles-attribute" role-mapper="kie-ldap-logical-default-role-mapper"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <logical-role-mapper name="kie-ldap-logical-default-role-mapper" logical-operation="or" left="kie-ldap-mapped-roles" right="kie-ldap-role-mapper"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security elytron-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <application-security-domain name="other" security-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <constant-role-mapper name="kie-ldap-role-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role name="test"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <mapped-role-mapper name="kie-ldap-mapped-roles" keep-mapped="false" keep-non-mapped="true">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role-mapping from="test" to="test"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role-mapping from="test" to="test"/>
    And file /opt/eat/standalone/deploy/ROOT/WEB-INF/jboss-web.xml should not contain <security-domain>other</security-domain>

  Scenario: Configure images to use LDAP authentication with default role, role recursion and users recursive search
    When container is started with env
      | variable                     | value                        |
      | AUTH_LDAP_URL                | test_url                     |
      | AUTH_LDAP_BIND_DN            | cn=Manager,dc=example,dc=com |
      | AUTH_LDAP_BIND_CREDENTIAL    | admin                        |
      | AUTH_LDAP_BASE_CTX_DN        | ou=Users,dc=example,dc=com   |
      | AUTH_LDAP_BASE_FILTER        | uid                          |
      | AUTH_LDAP_ROLE_ATTRIBUTE_ID  | cn                           |
      | AUTH_LDAP_ROLES_CTX_DN       | ou=Roles,dc=example,dc=com   |
      | AUTH_LDAP_ROLE_FILTER        | (member={1})                 |
      | AUTH_LDAP_DEFAULT_ROLE       | test                         |
      | AUTH_LDAP_RECURSIVE_SEARCH   | true                         |
      | AUTH_LDAP_ROLE_RECURSION     | 2                            |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <dir-context name="KIELdapDC" url="test_url" principal="cn=Manager,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <credential-reference clear-text="admin"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <attribute from="cn" to="Roles" filter="(member={1})" filter-base-dn="ou=Roles,dc=example,dc=com" role-recursion="2"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <ldap-realm name="KIELdapRealm" dir-context="KIELdapDC">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <identity-mapping rdn-identifier="uid" search-base-dn="ou=Users,dc=example,dc=com" use-recursive-search="true">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security-domain name="KIELdapSecurityDomain" default-realm="KIELdapRealm" permission-mapper="default-permission-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <realm name="KIELdapRealm" role-decoder="from-roles-attribute" role-mapper="kie-ldap-logical-default-role-mapper"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <logical-role-mapper name="kie-ldap-logical-default-role-mapper" logical-operation="or" left="kie-ldap-mapped-roles" right="kie-ldap-role-mapper"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security elytron-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <application-security-domain name="other" security-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <constant-role-mapper name="kie-ldap-role-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role name="test"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <mapped-role-mapper name="kie-ldap-mapped-roles" keep-mapped="false" keep-non-mapped="true">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role-mapping from="test" to="test"/>
    And file /opt/eat/standalone/deploy/ROOT/WEB-INF/jboss-web.xml should not contain <security-domain>other</security-domain>

  Scenario: Configure images to use LDAP authentication with role mapper properties
    When container is started with env
      | variable                           | value                        |
      | AUTH_LDAP_URL                      | test_url                     |
      | AUTH_LDAP_BIND_DN                  | cn=Manager,dc=example,dc=com |
      | AUTH_LDAP_BIND_CREDENTIAL          | admin                        |
      | AUTH_LDAP_BASE_CTX_DN              | ou=Users,dc=example,dc=com   |
      | AUTH_LDAP_BASE_FILTER              | uid                          |
      | AUTH_LDAP_ROLE_ATTRIBUTE_ID        | cn                           |
      | AUTH_LDAP_ROLES_CTX_DN             | ou=Roles,dc=example,dc=com   |
      | AUTH_LDAP_ROLE_FILTER              | (member={1})                 |
      | AUTH_ROLE_MAPPER_ROLES_PROPERTIES  | admin=PowerUser,BillingAdmin |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <dir-context name="KIELdapDC" url="test_url" principal="cn=Manager,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <credential-reference clear-text="admin"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <attribute from="cn" to="Roles" filter="(member={1})" filter-base-dn="ou=Roles,dc=example,dc=com"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <ldap-realm name="KIELdapRealm" dir-context="KIELdapDC">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <identity-mapping rdn-identifier="uid" search-base-dn="ou=Users,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security-domain name="KIELdapSecurityDomain" default-realm="KIELdapRealm" permission-mapper="default-permission-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <realm name="KIELdapRealm" role-decoder="from-roles-attribute" role-mapper="kie-custom-role-mapper"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security elytron-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <application-security-domain name="other" security-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <mapped-role-mapper name="kie-custom-role-mapper" keep-mapped="false" keep-non-mapped="false">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role-mapping from="admin" to="PowerUser BillingAdmin"/>
    And file /opt/eat/standalone/deploy/ROOT/WEB-INF/jboss-web.xml should not contain <security-domain>other</security-domain>

  Scenario: Configure images to use LDAP authentication with default role and role mapper properties
    When container is started with env
      | variable                           | value                        |
      | AUTH_LDAP_URL                      | test_url                     |
      | AUTH_LDAP_BIND_DN                  | cn=Manager,dc=example,dc=com |
      | AUTH_LDAP_BIND_CREDENTIAL          | admin                        |
      | AUTH_LDAP_BASE_CTX_DN              | ou=Users,dc=example,dc=com   |
      | AUTH_LDAP_BASE_FILTER              | uid                          |
      | AUTH_LDAP_ROLE_ATTRIBUTE_ID        | cn                           |
      | AUTH_LDAP_ROLES_CTX_DN             | ou=Roles,dc=example,dc=com   |
      | AUTH_LDAP_ROLE_FILTER              | (member={1})                 |
      | AUTH_LDAP_DEFAULT_ROLE             | test                         |
      | AUTH_ROLE_MAPPER_ROLES_PROPERTIES  | admin=PowerUser,BillingAdmin |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <dir-context name="KIELdapDC" url="test_url" principal="cn=Manager,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <credential-reference clear-text="admin"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <attribute from="cn" to="Roles" filter="(member={1})" filter-base-dn="ou=Roles,dc=example,dc=com"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <ldap-realm name="KIELdapRealm" dir-context="KIELdapDC">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <identity-mapping rdn-identifier="uid" search-base-dn="ou=Users,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security-domain name="KIELdapSecurityDomain" default-realm="KIELdapRealm" permission-mapper="default-permission-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <realm name="KIELdapRealm" role-decoder="from-roles-attribute" role-mapper="kie-ldap-logical-default-role-mapper"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <logical-role-mapper name="kie-ldap-logical-default-role-mapper" logical-operation="or" left="kie-ldap-mapped-roles" right="kie-ldap-role-mapper"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security elytron-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <application-security-domain name="other" security-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <constant-role-mapper name="kie-ldap-role-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role name="test"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <application-security-domain name="other" security-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <mapped-role-mapper name="kie-ldap-mapped-roles" keep-mapped="false" keep-non-mapped="true">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role-mapping from="test" to="test"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role-mapping from="admin" to="PowerUser BillingAdmin"/>
    And file /opt/eat/standalone/deploy/ROOT/WEB-INF/jboss-web.xml should not contain <security-domain>other</security-domain>

  Scenario: Configure images to use LDAP authentication with referral
    When container is started with env
      | variable                                      | value                        |
      | AUTH_LDAP_URL                                 | test_url                     |
      | AUTH_LDAP_BIND_DN                             | cn=Manager,dc=example,dc=com |
      | AUTH_LDAP_BIND_CREDENTIAL                     | admin                        |
      | AUTH_LDAP_BASE_CTX_DN                         | ou=Users,dc=example,dc=com   |
      | AUTH_LDAP_BASE_FILTER                         | uid                          |
      | AUTH_LDAP_ROLE_ATTRIBUTE_ID                   | cn                           |
      | AUTH_LDAP_ROLES_CTX_DN                        | ou=Roles,dc=example,dc=com   |
      | AUTH_LDAP_ROLE_FILTER                         | (member={1})                 |
      | AUTH_LDAP_REFERRAL_MODE                       | follow                       |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <dir-context name="KIELdapDC" url="test_url" referral-mode="follow" principal="cn=Manager,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <credential-reference clear-text="admin"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <attribute from="cn" to="Roles" filter="(member={1})" filter-base-dn="ou=Roles,dc=example,dc=com"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <ldap-realm name="KIELdapRealm" dir-context="KIELdapDC">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <identity-mapping rdn-identifier="uid" search-base-dn="ou=Users,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security-domain name="KIELdapSecurityDomain" default-realm="KIELdapRealm" permission-mapper="default-permission-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security elytron-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <application-security-domain name="other" security-domain="KIELdapSecurityDomain"/>
    And file /opt/eat/standalone/deploy/ROOT/WEB-INF/jboss-web.xml should not contain <security-domain>other</security-domain>

  Scenario: Configure images to use LDAP authentication with referral
    When container is started with env
      | variable                                      | value                        |
      | AUTH_LDAP_URL                                 | test_url                     |
      | AUTH_LDAP_BIND_DN                             | cn=Manager,dc=example,dc=com |
      | AUTH_LDAP_BIND_CREDENTIAL                     | admin                        |
      | AUTH_LDAP_BASE_CTX_DN                         | ou=Users,dc=example,dc=com   |
      | AUTH_LDAP_BASE_FILTER                         | uid                          |
      | AUTH_LDAP_ROLE_ATTRIBUTE_ID                   | cn                           |
      | AUTH_LDAP_ROLES_CTX_DN                        | ou=Roles,dc=example,dc=com   |
      | AUTH_LDAP_ROLE_FILTER                         | (member={1})                 |
      | AUTH_LDAP_DEFAULT_ROLE                        | test                         |
      | AUTH_LDAP_ROLE_RECURSION                      | 100                          |
      | AUTH_LDAP_REFERRAL_MODE                       | follow                       |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <dir-context name="KIELdapDC" url="test_url" referral-mode="follow" principal="cn=Manager,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <credential-reference clear-text="admin"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <attribute from="cn" to="Roles" filter="(member={1})" filter-base-dn="ou=Roles,dc=example,dc=com" role-recursion="100"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <ldap-realm name="KIELdapRealm" dir-context="KIELdapDC">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <identity-mapping rdn-identifier="uid" search-base-dn="ou=Users,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security-domain name="KIELdapSecurityDomain" default-realm="KIELdapRealm" permission-mapper="default-permission-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <realm name="KIELdapRealm" role-decoder="from-roles-attribute" role-mapper="kie-ldap-logical-default-role-mapper"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security elytron-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <application-security-domain name="other" security-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <constant-role-mapper name="kie-ldap-role-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role name="test"/>
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value KIELdapRealm on XPath //*[local-name()='mechanism-realm']/@realm-name
    And file /opt/eat/standalone/deploy/ROOT/WEB-INF/jboss-web.xml should not contain <security-domain>other</security-domain>

  Scenario: Configure images to use LDAP authentication with search time limit and blank password
    When container is started with env
      | variable                                      | value                        |
      | AUTH_LDAP_URL                                 | test_url                     |
      | AUTH_LDAP_BIND_DN                             | cn=Manager,dc=example,dc=com |
      | AUTH_LDAP_BIND_CREDENTIAL                     | admin                        |
      | AUTH_LDAP_BASE_CTX_DN                         | ou=Users,dc=example,dc=com   |
      | AUTH_LDAP_BASE_FILTER                         | uid                          |
      | AUTH_LDAP_ROLE_ATTRIBUTE_ID                   | cn                           |
      | AUTH_LDAP_ROLES_CTX_DN                        | ou=Roles,dc=example,dc=com   |
      | AUTH_LDAP_ROLE_FILTER                         | (member={1})                 |
      | AUTH_LDAP_ALLOW_EMPTY_PASSWORDS               | true                         |
      | AUTH_LDAP_DEFAULT_ROLE                        | test                         |
      | AUTH_LDAP_ROLE_RECURSION                      | 34                           |
      | AUTH_LDAP_SEARCH_TIME_LIMIT                   | 1000                         |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <dir-context name="KIELdapDC" url="test_url" read-timeout="1000" principal="cn=Manager,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <credential-reference clear-text="admin"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <attribute from="cn" to="Roles" filter="(member={1})" filter-base-dn="ou=Roles,dc=example,dc=com" role-recursion="34"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <ldap-realm name="KIELdapRealm" direct-verification="true" allow-blank-password="true" dir-context="KIELdapDC">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <identity-mapping rdn-identifier="uid" search-base-dn="ou=Users,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security-domain name="KIELdapSecurityDomain" default-realm="KIELdapRealm" permission-mapper="default-permission-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <realm name="KIELdapRealm" role-decoder="from-roles-attribute" role-mapper="kie-ldap-logical-default-role-mapper"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security elytron-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <application-security-domain name="other" security-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <constant-role-mapper name="kie-ldap-role-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role name="test"/>
    And file /opt/eat/standalone/deploy/ROOT/WEB-INF/jboss-web.xml should not contain <security-domain>other</security-domain>

  Scenario: Configure images to use LDAP authentication with search time limit and referral mode
    When container is started with env
      | variable                                      | value                        |
      | AUTH_LDAP_URL                                 | test_url                     |
      | AUTH_LDAP_BIND_DN                             | cn=Manager,dc=example,dc=com |
      | AUTH_LDAP_BIND_CREDENTIAL                     | admin                        |
      | AUTH_LDAP_BASE_CTX_DN                         | ou=Users,dc=example,dc=com   |
      | AUTH_LDAP_BASE_FILTER                         | uid                          |
      | AUTH_LDAP_ROLE_ATTRIBUTE_ID                   | cn                           |
      | AUTH_LDAP_ROLES_CTX_DN                        | ou=Roles,dc=example,dc=com   |
      | AUTH_LDAP_ROLE_FILTER                         | (member={1})                 |
      | AUTH_LDAP_ALLOW_EMPTY_PASSWORDS               | true                         |
      | AUTH_LDAP_DEFAULT_ROLE                        | test                         |
      | AUTH_LDAP_ROLE_RECURSION                      | 2434                         |
      | AUTH_LDAP_SEARCH_TIME_LIMIT                   | 1000                         |
      | AUTH_LDAP_REFERRAL_MODE                       | follow                       |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <dir-context name="KIELdapDC" url="test_url" read-timeout="1000" referral-mode="follow" principal="cn=Manager,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <credential-reference clear-text="admin"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <attribute from="cn" to="Roles" filter="(member={1})" filter-base-dn="ou=Roles,dc=example,dc=com" role-recursion="2434"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <ldap-realm name="KIELdapRealm" direct-verification="true" allow-blank-password="true" dir-context="KIELdapDC">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <identity-mapping rdn-identifier="uid" search-base-dn="ou=Users,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security-domain name="KIELdapSecurityDomain" default-realm="KIELdapRealm" permission-mapper="default-permission-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <realm name="KIELdapRealm" role-decoder="from-roles-attribute" role-mapper="kie-ldap-logical-default-role-mapper"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security elytron-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <application-security-domain name="other" security-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <constant-role-mapper name="kie-ldap-role-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role name="test"/>
    And container log should not contain Provided referral mode [FOLLOW] is not valid, ignoring referral mode, the valid ones are FOLLOW IGNORE THROW
    And file /opt/eat/standalone/deploy/ROOT/WEB-INF/jboss-web.xml should not contain <security-domain>other</security-domain>

  Scenario: Configure images to use LDAP authentication with search time limit and referral mode with ldap failover enabled
    When container is started with env
      | variable                                      | value                        |
      | AUTH_LDAP_URL                                 | test_url                     |
      | AUTH_LDAP_BIND_DN                             | cn=Manager,dc=example,dc=com |
      | AUTH_LDAP_BIND_CREDENTIAL                     | admin                        |
      | AUTH_LDAP_BASE_CTX_DN                         | ou=Users,dc=example,dc=com   |
      | AUTH_LDAP_BASE_FILTER                         | uid                          |
      | AUTH_LDAP_ROLE_ATTRIBUTE_ID                   | cn                           |
      | AUTH_LDAP_ROLES_CTX_DN                        | ou=Roles,dc=example,dc=com   |
      | AUTH_LDAP_ROLE_FILTER                         | (member={1})                 |
      | AUTH_LDAP_ALLOW_EMPTY_PASSWORDS               | true                         |
      | AUTH_LDAP_DEFAULT_ROLE                        | test                         |
      | AUTH_LDAP_ROLE_RECURSION                      | 2434                         |
      | AUTH_LDAP_SEARCH_TIME_LIMIT                   | 1000                         |
      | AUTH_LDAP_REFERRAL_MODE                       | follow                       |
      | AUTH_LDAP_LOGIN_FAILOVER                      | true                         |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <dir-context name="KIELdapDC" url="test_url" read-timeout="1000" referral-mode="follow" principal="cn=Manager,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <credential-reference clear-text="admin"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <attribute from="cn" to="Roles" filter="(member={1})" filter-base-dn="ou=Roles,dc=example,dc=com" role-recursion="2434"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <ldap-realm name="KIELdapRealm" direct-verification="true" allow-blank-password="true" dir-context="KIELdapDC">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <identity-mapping rdn-identifier="uid" search-base-dn="ou=Users,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security-domain name="KIELdapWithFailOverSecDomain" default-realm="KIEFailOverRealm" permission-mapper="default-permission-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <realm name="KIEFailOverRealm" role-decoder="kie-aggregate-role-decoder" role-mapper="kie-ldap-logical-default-role-mapper"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security elytron-domain="KIELdapWithFailOverSecDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <application-security-domain name="other" security-domain="KIELdapWithFailOverSecDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <constant-role-mapper name="kie-ldap-role-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role name="test"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <failover-realm name="KIEFailOverRealm" delegate-realm="KIELdapRealm" failover-realm="KieFsRealm"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <aggregate-role-decoder name="kie-aggregate-role-decoder">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role-decoder name="from-roles-attribute"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role-decoder name="from-role-attribute"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain </aggregate-role-decoder>
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value KIEFailOverRealm on XPath //*[local-name()='mechanism-realm']/@realm-name
    And file /opt/eat/standalone/deploy/ROOT/WEB-INF/jboss-web.xml should not contain <security-domain>other</security-domain>

  Scenario: Configure images to use LDAP authentication with search time limit and referral mode with ldap login module set to optional
    When container is started with env
      | variable                                      | value                        |
      | AUTH_LDAP_URL                                 | test_url                     |
      | AUTH_LDAP_BIND_DN                             | cn=Manager,dc=example,dc=com |
      | AUTH_LDAP_BIND_CREDENTIAL                     | admin                        |
      | AUTH_LDAP_BASE_CTX_DN                         | ou=Users,dc=example,dc=com   |
      | AUTH_LDAP_BASE_FILTER                         | uid                          |
      | AUTH_LDAP_ROLE_ATTRIBUTE_ID                   | cn                           |
      | AUTH_LDAP_ROLES_CTX_DN                        | ou=Roles,dc=example,dc=com   |
      | AUTH_LDAP_ROLE_FILTER                         | (member={1})                 |
      | AUTH_LDAP_ALLOW_EMPTY_PASSWORDS               | true                         |
      | AUTH_LDAP_DEFAULT_ROLE                        | test                         |
      | AUTH_LDAP_ROLE_RECURSION                      | 2434                         |
      | AUTH_LDAP_SEARCH_TIME_LIMIT                   | 1000                         |
      | AUTH_LDAP_REFERRAL_MODE                       | follow                       |
      | AUTH_LDAP_LOGIN_MODULE                        | optional                     |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <dir-context name="KIELdapDC" url="test_url" read-timeout="1000" referral-mode="follow" principal="cn=Manager,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <credential-reference clear-text="admin"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <attribute from="cn" to="Roles" filter="(member={1})" filter-base-dn="ou=Roles,dc=example,dc=com" role-recursion="2434"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <ldap-realm name="KIELdapRealm" direct-verification="true" allow-blank-password="true" dir-context="KIELdapDC">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <identity-mapping rdn-identifier="uid" search-base-dn="ou=Users,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security-domain name="KIELdapSecurityDomain" default-realm="KIEDistributedRealm" permission-mapper="default-permission-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <realm name="KIEDistributedRealm" role-decoder="kie-aggregate-role-decoder" role-mapper="kie-ldap-logical-default-role-mapper"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security elytron-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <application-security-domain name="other" security-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <constant-role-mapper name="kie-ldap-role-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role name="test"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <distributed-realm name="KIEDistributedRealm" realms="KIELdapRealm KieFsRealm"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <aggregate-role-decoder name="kie-aggregate-role-decoder">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role-decoder name="from-roles-attribute"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role-decoder name="from-role-attribute"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain </aggregate-role-decoder>
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value KIEDistributedRealm on XPath //*[local-name()='mechanism-realm']/@realm-name
    And file /opt/eat/standalone/deploy/ROOT/WEB-INF/jboss-web.xml should not contain <security-domain>other</security-domain>

  Scenario: Check LDAP Base Filter is correctly configured if AUTH_LDAP_BASE_FILTER contains special char '&' and '|'
    When container is started with env
      | variable                    | value                                                                |
      | AUTH_LDAP_URL               | test_url                                                             |
      | AUTH_LDAP_BIND_DN           | cn=Manager,dc=example,dc=com                                         |
      | AUTH_LDAP_BIND_CREDENTIAL   | admin                                                                |
      | AUTH_LDAP_BASE_CTX_DN       | ou=Users,dc=example,dc=com                                           |
      | AUTH_LDAP_ROLE_FILTER       | (&(objectClass=groupOfUniqueNames)(uniqueMember={1}))                |
      | AUTH_LDAP_ROLE_ATTRIBUTE_ID | cn                                                                   |
      | AUTH_LDAP_ROLES_CTX_DN      | ou=Roles,dc=example,dc=com                                           |
      | AUTH_LDAP_BASE_FILTER       | (&(mail={0}))(\|(objectclass=dbperson)(objectclass=inetOrgPerson)))  |
      | SCRIPT_DEBUG                | true                                                                 |
    Then container log should contain AUTH_LDAP_URL is set to [test_url], setting up LDAP authentication with elytron...
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <dir-context name="KIELdapDC" url="test_url" principal="cn=Manager,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <credential-reference clear-text="admin"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <attribute from="cn" to="Roles" filter="(&amp;(objectClass=groupOfUniqueNames)(uniqueMember={1}))" filter-base-dn="ou=Roles,dc=example,dc=com"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <identity-mapping rdn-identifier="(&amp;(mail={0}))(|(objectclass=dbperson)(objectclass=inetOrgPerson)))" search-base-dn="ou=Users,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security-domain name="KIELdapSecurityDomain" default-realm="KIELdapRealm" permission-mapper="default-permission-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security elytron-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <application-security-domain name="other" security-domain="KIELdapSecurityDomain"/>
    And file /opt/eat/standalone/deploy/ROOT/WEB-INF/jboss-web.xml should not contain <security-domain>other</security-domain>

  Scenario: Check LDAP Base Filter is correctly configured if AUTH_LDAP_BASE_FILTER contains special char '&' and '|' and AUTH_LDAP_BIND_CREDENTIAL with special characters
    When container is started with env
      | variable                    | value                                                                |
      | AUTH_LDAP_URL               | test_url                                                             |
      | AUTH_LDAP_BIND_DN           | cn=Manager,dc=example,dc=com                                         |
      | AUTH_LDAP_BIND_CREDENTIAL   | P&s$w1'"ord                                                          |
      | AUTH_LDAP_BASE_CTX_DN       | ou=Users,dc=example,dc=com                                           |
      | AUTH_LDAP_ROLE_FILTER       | (member={1})                                                         |
      | AUTH_LDAP_ROLE_ATTRIBUTE_ID | cn                                                                   |
      | AUTH_LDAP_ROLES_CTX_DN      | ou=Roles,dc=example,dc=com                                           |
      | AUTH_LDAP_BASE_FILTER       | (&(mail={0}))(\|(objectclass=dbperson)(objectclass=inetOrgPerson)))  |
      | SCRIPT_DEBUG                | true                                                                 |
    Then container log should contain AUTH_LDAP_URL is set to [test_url], setting up LDAP authentication with elytron...
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <dir-context name="KIELdapDC" url="test_url" principal="cn=Manager,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <credential-reference clear-text="P&amp;s$w1'&quot;ord"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <attribute from="cn" to="Roles" filter="(member={1})" filter-base-dn="ou=Roles,dc=example,dc=com"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <identity-mapping rdn-identifier="(&amp;(mail={0}))(|(objectclass=dbperson)(objectclass=inetOrgPerson)))" search-base-dn="ou=Users,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security-domain name="KIELdapSecurityDomain" default-realm="KIELdapRealm" permission-mapper="default-permission-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security elytron-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <application-security-domain name="other" security-domain="KIELdapSecurityDomain"/>
    And file /opt/eat/standalone/deploy/ROOT/WEB-INF/jboss-web.xml should not contain <security-domain>other</security-domain>

  Scenario: Check if eap users are not being created if SSO is configured with no users env
    When container is started with env
      | variable                   | value         |
      | SSO_URL                    | http://url    |
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain adminUser
    And file /opt/eap/standalone/configuration/application-roles.properties should not contain adminUser
    And container log should contain External authentication/authorization enabled, skipping the embedded users creation.
    And container log should contain Make sure to configure KIE_ADMIN_USER user to access the application with the roles kie-server,rest-all,admin,kiemgmt,Administrators,user

  Scenario: Check if elytron is correctly configured when SSO is enabled.
    When container is started with env
      | variable                   | value         |
      | SSO_URL                    | http://url    |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <custom-realm name="KeycloakOIDCRealm" module="org.keycloak.keycloak-wildfly-elytron-oidc-adapter" class-name="org.keycloak.adapters.elytron.KeycloakSecurityRealm"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security-domain name="KeycloakDomain" default-realm="KeycloakOIDCRealm" permission-mapper="default-permission-mapper" security-event-listener="local-audit">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <realm name="KeycloakOIDCRealm"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <constant-realm-mapper name="keycloak-oidc-realm-mapper" realm-name="KeycloakOIDCRealm"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <aggregate-http-server-mechanism-factory name="keycloak-http-server-mechanism-factory">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <http-server-mechanism-factory name="keycloak-oidc-http-server-mechanism-factory"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <service-loader-http-server-mechanism-factory name="keycloak-oidc-http-server-mechanism-factory" module="org.keycloak.keycloak-wildfly-elytron-oidc-adapter"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <http-authentication-factory name="keycloak-http-authentication" security-domain="KeycloakDomain" http-server-mechanism-factory="keycloak-http-server-mechanism-factory">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <mechanism mechanism-name="KEYCLOAK">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <mechanism-realm realm-name="KeycloakOIDCRealm" realm-mapper="keycloak-oidc-realm-mapper"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <application-security-domain name="other" http-authentication-factory="keycloak-http-authentication"/>
  # https://issues.jboss.org/browse/RHPAM-89
  # https://issues.jboss.org/browse/RHPAM-1135
  Scenario: Check custom users are properly configured
    When container is started with env
      | variable       | value         |
      | KIE_ADMIN_USER | customAdm     |
      | KIE_ADMIN_PWD  | custom" Adm!0 |
    Then file /opt/eap/standalone/configuration/application-users.properties should contain customAdm=a4d41e50a4ae17a50c1ceabe21e41a80
    And file /opt/eap/standalone/configuration/application-roles.properties should contain customAdm=kie-server,rest-all,admin,kiemgmt,Administrators,user

  Scenario: Check custom users with custom roles are properly configured
    When container is started with env
      | variable        | value         |
      | KIE_ADMIN_USER  | customAdm     |
      | KIE_ADMIN_PWD   | custom" Adm!0 |
      | KIE_ADMIN_ROLES | role1,admin2  |
    Then file /opt/eap/standalone/configuration/application-users.properties should contain customAdm=a4d41e50a4ae17a50c1ceabe21e41a80
    And file /opt/eap/standalone/configuration/application-roles.properties should contain customAdm=role1,admin2

  # https://issues.jboss.org/browse/RHPAM-891
  Scenario: Check default users are properly configured
    When container is ready
    Then file /opt/eap/standalone/configuration/application-users.properties should contain adminUser=de3155e1927c6976555925dec24a53ac
    And file /opt/eap/standalone/configuration/application-roles.properties should contain adminUser=kie-server,rest-all,admin,kiemgmt,Administrators