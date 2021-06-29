@rhdm-7/rhdm-decisioncentral-rhel8 @rhpam-7/rhpam-businesscentral-rhel8
Feature: Decision/Business Central common features

  Scenario: Web console is available
    When container is ready
    Then check that page is served
      | property             | value        |
      | port                 | 8080         |
      | path                 | /kie-wb.jsp  |
      | expected_status_code | 200          |
      | wait                 | 120          |

  Scenario: Check custom workbench users are properly configured
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
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain customAdm
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customAdm
     And container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain KIE_ADMIN_USER is set to customAdm, make sure to configure this user with the provided password on the external auth provider with the roles kie-server,rest-all,admin,kiemgmt,Administrators,user

  Scenario: Check if eap users are not being created if SSO is configured with no users env
    When container is started with env
      | variable                    | value         |
      | SSO_URL                     | http://url    |
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain adminUser
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain adminUser
     And container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain Make sure to configure KIE_ADMIN_USER user to access the application with the roles kie-server,rest-all,admin,kiemgmt,Administrators,user

  Scenario: Check if eap users are not being created if LDAP is configured with no users env
    When container is started with env
      | variable                    | value         |
      | AUTH_LDAP_URL               | ldap://url:389|
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain adminUser
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain adminUser
     And container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain Make sure to configure KIE_ADMIN_USER user to access the application with the roles kie-server,rest-all,admin,kiemgmt,Administrators,user

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

  Scenario: Check if the GC_MAX_METASPACE_SIZE is set to 1024 if WORKBENCH_MAX_METASPACE_SIZE is not set
    When container is ready
    Then container log should contain -XX:MaxMetaspaceSize=1024m

  Scenario: Check if the WORKBENCH_MAX_METASPACE_SIZE is correctly set
    When container is started with env
      | variable                       | value   |
      | WORKBENCH_MAX_METASPACE_SIZE   | 2048    |
    Then container log should contain -XX:MaxMetaspaceSize=2048m

  Scenario: Check if the GC_MAX_METASPACE_SIZE is correctly set and bypass WORKBENCH_MAX_METASPACE_SIZE env
    When container is started with env
      | variable                | value   |
      | GC_MAX_METASPACE_SIZE   | 4096    |
    Then container log should contain -XX:MaxMetaspaceSize=4096m

  Scenario: Check if the WORKBENCH_MAX_METASPACE_SIZE takes precedence when WORKBENCH_MAX_METASPACE_SIZE and GC_MAX_METASPACE_SIZE are set
    When container is started with env
      | variable                       | value   |
      | WORKBENCH_MAX_METASPACE_SIZE   | 4096    |
      | GC_MAX_METASPACE_SIZE          | 2048    |
    Then container log should contain -XX:MaxMetaspaceSize=4096m

  Scenario: Check if index files are in shared PV
    When container is ready
    Then container log should contain -Dorg.uberfire.metadata.index.dir=/opt/kie/data

  Scenario: RHPAM-3517: Update maven to 3.6
    When container is started with command bash
    Then run sh -c "mvn --version | sed -n -e 's/^.*Apache //p' | grep 3.6 && echo  all good" in container and check its output for all good

  Scenario: Test if KIE Server access is correct set with user/pass
    When container is started with env
      | variable       | value     |
      | KIE_ADMIN_USER | superUser |
      | KIE_ADMIN_PWD  | @w3s0m3   |
    Then container log should contain -Dorg.kie.server.user=superUser
     And container log should contain -Dorg.kie.server.pwd=@w3s0m3
     And container log should not contain -Dorg.kie.server.token

  Scenario: Test if KIE Server access is correct set with token
    When container is started with env
      | variable         | value             |
      | KIE_ADMIN_USER   | superUser         |
      | KIE_ADMIN_PWD    | @w3s0m3           |
      | KIE_SERVER_TOKEN | some-random-token |
    Then container log should not contain -Dorg.kie.server.user
     And container log should not contain -Dorg.kie.server.pwd
     And container log should contain -Dorg.kie.server.token=some-random-token

  Scenario: Test if the Controller access is correctly configure with user/pass
    When container is started with env
      | variable                    | value                  |
      | KIE_SERVER_CONTROLLER_HOST  | https://localhost:8443 |
      | KIE_ADMIN_USER              | superUser              |
      | KIE_ADMIN_PWD               | @w3s0m3                |
    Then container log should contain -Dorg.kie.server.controller=http://https://localhost:8443:8080/rest/controller
     And container log should contain -Dorg.kie.server.controller.user=superUser
     And container log should contain -Dorg.kie.server.controller.pwd=@w3s0m3
     And container log should not contain -Dorg.kie.server.controller.token

  Scenario: Test if the Controller access is correctly configure with token
    When container is started with env
      | variable                    | value                  |
      | KIE_SERVER_CONTROLLER_HOST  | https://localhost:8443 |
      | KIE_ADMIN_USER              | superUser              |
      | KIE_ADMIN_PWD               | @w3s0m3                |
      | KIE_SERVER_CONTROLLER_TOKEN | some-random-token      |
    Then container log should contain -Dorg.kie.server.controller=http://https://localhost:8443:8080/rest/controller
     And container log should not contain -Dorg.kie.server.controller.user
     And container log should not contain -Dorg.kie.server.controller.pwd
     And container log should contain -Dorg.kie.server.controller.token=some-random-token
