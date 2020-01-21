@rhdm-7/rhdm-decisioncentral-rhel8 @rhpam-7/rhpam-businesscentral-rhel8
Feature: Decision/Business Central common features

  Scenario: Check custom users are properly configured
    When container is started with env
      | variable                    | value         |
      | KIE_ADMIN_USER              | customAdm     |
      | KIE_ADMIN_PWD               | custom" Adm!0 |
      | KIE_ADMIN_ROLES             | role1,admin2  |
    Then file /opt/eap/standalone/configuration/application-users.properties should contain customAdm=a4d41e50a4ae17a50c1ceabe21e41a80
     And file /opt/eap/standalone/configuration/application-roles.properties should contain customAdm=role1,admin2
     And container log should contain -Dorg.uberfire.ext.security.management.api.userManagementServices=WildflyCLIUserManagementService
     And container log should not contain -Dorg.uberfire.ext.security.management.keycloak.authServer
     And container log should not contain -Dorg.jbpm.workbench.kie_server.keycloak

  Scenario: Check if eap users are not being created if SSO is configured
    When container is started with env
      | variable                    | value         |
      | SSO_URL                     | http://url    |
      | KIE_ADMIN_USER              | customAdm     |
      | KIE_ADMIN_PWD               | custom" Adm!0 |
      | KIE_ADMIN_ROLES             | role1,admin2  |
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain customAdm=a4d41e50a4ae17a50c1ceabe21e41a80
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customAdm=role1,admin2
     And container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain KIE_ADMIN_USER is set to customAdm, make sure to configure this user with the provided password on the external auth provider with the roles role1,admin2
     And container log should contain -Dorg.uberfire.ext.security.management.api.userManagementServices=KCAdapterUserManagementService
     And container log should contain -Dorg.uberfire.ext.security.management.keycloak.authServer=http://url
     And container log should contain -Dorg.jbpm.workbench.kie_server.keycloak=true

  Scenario: Check if eap users are not being created if LDAP is configured
    When container is started with env
      | variable                    | value         |
      | AUTH_LDAP_URL               | ldap://url:389|
      | KIE_ADMIN_USER              | customAdm     |
      | KIE_ADMIN_PWD               | custom" Adm!0 |
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain customAdm=a4d41e50a4ae17a50c1ceabe21e41a80
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customAdm=role1,admin2
     And container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain KIE_ADMIN_USER is set to customAdm, make sure to configure this user with the provided password on the external auth provider with the roles kie-server,rest-all,admin,kiemgmt,Administrators

  Scenario: Check if eap users are not being created if SSO is configured with no users env
    When container is started with env
      | variable                    | value         |
      | SSO_URL                     | http://url    |
    Then container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain Make sure to configure a ADMIN user with the roles kie-server,rest-all,admin,kiemgmt,Administrators

  Scenario: Check if eap users are not being created if LDAP is configured with no users env
    When container is started with env
      | variable                    | value         |
      | AUTH_LDAP_URL               | ldap://url:389|
    Then container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain Make sure to configure a ADMIN user with the roles kie-server,rest-all,admin,kiemgmt,Administrators

  # https://issues.jboss.org/browse/KIECLOUD-218
  # https://issues.jboss.org/browse/JBPM-8400
  Scenario: Check for kie keystore
    When container is ready
    Then container log should contain -Dkie.keystore.keyStoreURL=file:///opt/eap/standalone/configuration/kie-keystore.jceks

  # https://issues.jboss.org/browse/AF-2240
  Scenario: Check that thread limit settings are respected
    When container is started with env
      | variable                                    | value |
      | APPFORMER_CONCURRENT_MANAGED_THREAD_LIMIT   | 1234  |
      | APPFORMER_CONCURRENT_UNMANAGED_THREAD_LIMIT | 4321  |
    Then container log should contain -Dorg.appformer.concurrent.managed.thread.limit=1234
     And container log should contain -Dorg.appformer.concurrent.unmanaged.thread.limit=4321

  # https://issues.jboss.org/browse/AF-2240
    Scenario: Check that thread limit settings use defaults
    When container is ready
    Then container log should contain -Dorg.appformer.concurrent.managed.thread.limit=1000
     And container log should contain -Dorg.appformer.concurrent.unmanaged.thread.limit=1000
