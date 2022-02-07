@rhdm-7/rhdm-kieserver-rhel8
@rhpam-7/rhpam-kieserver-rhel8
@rhdm-7/rhdm-decisioncentral-rhel8
@rhpam-7/rhpam-businesscentral-rhel8
@rhpam-7/rhpam-businesscentral-monitoring-rhel8
@rhpam-7/rhpam-dashbuilder-rhel8
@rhpam-7/rhpam-controller-rhel8
@rhdm-7/rhdm-controller-rhel8
Feature: RHPAM and RHDM common tests

  Scenario: Ensure the openjdk8 packages are not installed on container.
    When container is started with command bash
    Then run sh -c '/usr/bin/rpm -q java-1.8.0-openjdk-devel || true' in container and check its output contains package java-1.8.0-openjdk-devel is not installed
     And run sh -c '/usr/bin/rpm -q java-1.8.0-openjdk-headless || true' in container and check its output for package java-1.8.0-openjdk-headless is not installed
     And run sh -c '/usr/bin/rpm -q java-1.8.0-openjdk || true' in container and check its output for package java-1.8.0-openjdk is not installed

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
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security elytron-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <application-security-domain name="other" security-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <constant-role-mapper name="kie-ldap-role-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role name="test"/>
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
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security elytron-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <application-security-domain name="other" security-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <constant-role-mapper name="kie-ldap-role-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role name="test"/>
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
      | AUTH_LDAP_ROLE_FILTER       | (member={1})                                                         |
      | AUTH_LDAP_ROLE_ATTRIBUTE_ID | cn                                                                   |
      | AUTH_LDAP_ROLES_CTX_DN      | ou=Roles,dc=example,dc=com                                           |
      | AUTH_LDAP_BASE_FILTER       | (&(mail={0}))(\|(objectclass=dbperson)(objectclass=inetOrgPerson)))  |
      | SCRIPT_DEBUG                | true                                                            |
    Then container log should contain AUTH_LDAP_URL is set to [test_url], setting up LDAP authentication with elytron...
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <dir-context name="KIELdapDC" url="test_url" principal="cn=Manager,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <credential-reference clear-text="admin"/>
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

  Scenario: [KIECLOUD-520] - Make sure the jmx_prometheus_agent is on the desired version
    When container is started with command bash
    Then run sh -c 'test -f /opt/jboss/container/prometheus/jmx_prometheus_javaagent-0.3.2.redhat-00003.jar && echo all good' in container and check its output for all good
    And run sh -c 'md5sum /opt/jboss/container/prometheus/jmx_prometheus_javaagent-0.3.2.redhat-00003.jar' in container and check its output for 8b3af39995b113baf35e53468bad7aae  /opt/jboss/container/prometheus/jmx_prometheus_javaagent-0.3.2.redhat-00003.jar

  Scenario: Make sure the logger pattern is properly configured with a custom pattern
    When container is started with env
      | variable          | value                                           |
      | LOGGER_PATTERN    | %d{yyyy-MM-dd HH:mm:ss.SSS} %-5p [%c{1}] %m%n   |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <pattern-formatter pattern="%d{yyyy-MM-dd HH:mm:ss.SSS} %-5p [%c{1}] %m%n"/>

  Scenario: Make sure the logger pattern is properly configured with a defaut pattern
    When container is started with env
      | variable          | value                                             |
      | LOGGER_PATTERN    | %K{level}%d{HH:mm:ss,SSS} %-5p [%c] (%t) %s%e%n   |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <pattern-formatter pattern="%K{level}%d{HH:mm:ss,SSS} %-5p [%c] (%t) %s%e%n"/>

  Scenario: [KIECLOUD-592] - Verify JBoss contains only the needed files and folders
     When container is started with command bash
     Then run sh -c "[ ! -d "$JBOSS_HOME/domain/" ] && echo Directory domain DOES NOT exists." in container and check its output for domain DOES NOT exists
     Then run sh -c "[ ! -d "$JBOSS_HOME/migration/" ] && echo Directory migration DOES NOT exists." in container and check its output for migration DOES NOT exists
     Then run sh -c "[ -d "$JBOSS_HOME/.installation/" ]  && [ $(ls -1 $JBOSS_HOME/.installation/* 2>/dev/null | wc -l) -eq 0 ] &&  echo Directory .installation is empty." in container and check its output for .installation is empty.
     Then run sh -c "[ ! -d "$JBOSS_HOME/bin/init.d/" ] && echo Directory init.d DOES NOT exists." in container and check its output for init.d DOES NOT exists
     Then run sh -c "[ $(ls -1 $JBOSS_HOME/bin/*.bat 2>/dev/null | wc -l) -eq 0 ] && echo Success no BAT files" in container and check its output for Success no BAT files
     Then run sh -c "[ $(ls -1 $JBOSS_HOME/bin/*.ps1 2>/dev/null | wc -l) -eq 0 ] && echo Success no PS1 files" in container and check its output for Success no PS1 files
     Then run sh -c "[ $(ls -1 $JBOSS_HOME/bin/domain* 2>/dev/null | wc -l) -eq 0 ] && echo Success no domain files" in container and check its output for Success no domain files
     Then run sh -c "[ $(ls -1 $JBOSS_HOME/standalone/configuration/standalone-*.xml 2>/dev/null | wc -l) -eq 1 ] && echo Deleted files successfully" in container and check its output for Deleted files successfully
     Then run sh -c "[ -f $JBOSS_HOME/standalone/configuration/standalone-openshift.xml ] && echo Standalone Openshift is still there" in container and check its output for Standalone Openshift is still there