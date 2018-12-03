@rhdm-7/rhdm71-kieserver-openshift  @rhpam-7/rhpam71-kieserver-openshift
Feature: Kie Server common features

  Scenario: Check if kieserver mgmt is correctly set.
    When container is started with env
      | variable                   | value  |
      | KIE_SERVER_MGMT_DISABLED   | true   |
    Then container log should contain -Dorg.kie.server.mgmt.api.disabled=true

  Scenario: Test REST API is available and valid
    When container is started with env
      | variable         | value       |
      | KIE_SERVER_USER  | kieserver   |
      | KIE_SERVER_PWD   | kieserver1! |
    Then check that page is served
      | property        | value                 |
      | port            | 8080                  |
      | path            | /services/rest/server |
      | wait            | 80                    |
      | username        | kieserver             |
      | password        | kieserver1!           |
      | expected_phrase | SUCCESS               |

  Scenario: Configure kie server to be immutable, disable management and set startup strategy
    When container is started with env
      | variable                    | value                          |
      | KIE_SERVER_MGMT_DISABLED    | true                           |
      | KIE_SERVER_STARTUP_STRATEGY | LocalContainersStartupStrategy |
    Then container log should contain -Dorg.kie.server.mgmt.api.disabled=true
     And container log should contain -Dorg.kie.server.startup.strategy=LocalContainersStartupStrategy

  Scenario: Configure kie server to be immutable, disable management and set startup strategy
    When container is started with env
      | variable                    | value                          |
      | KIE_SERVER_MGMT_DISABLED    | true                           |
      | KIE_SERVER_STARTUP_STRATEGY | ControllerBasedStartupStrategy |
    Then container log should contain -Dorg.kie.server.mgmt.api.disabled=true
    And container log should contain -Dorg.kie.server.startup.strategy=ControllerBasedStartupStrategy

  Scenario: Configure kie server to be immutable, disable management and set a invalid startup strategy
    When container is started with env
      | variable                    | value    |
      | KIE_SERVER_MGMT_DISABLED    | true     |
      | KIE_SERVER_STARTUP_STRATEGY | invalid  |
    Then container log should contain -Dorg.kie.server.mgmt.api.disabled=true
    And container log should contain The startup strategy invalid is not valid, the valid strategies are LocalContainersStartupStrategy and ControllerBasedStartupStrategy

  Scenario: Test the KIE_SERVER_HOST configuration to default value
    When container is ready
    Then container log should contain Fail to query the route name using Kubernetes API

  Scenario: Test the KIE_SERVER_HOST configuration with custom host
    When container is started with env
      | variable           | value                      |
      | KIE_SERVER_HOST    | my-custon-host.example.com |
      | KIE_SERVER_PORT    | 80                         |
    Then container log should contain -Dorg.kie.server.location=http://my-custon-host.example.com:80/services/rest/server

  Scenario: Test the KIE_SERVER_HOST configuration with custom host with default port
    When container is started with env
      | variable           | value                      |
      | KIE_SERVER_HOST    | my-custon-host.example.com |
    Then container log should contain -Dorg.kie.server.location=http://my-custon-host.example.com:80/services/rest/server

  Scenario: Test the KIE_SERVER_HOST with no value provided
    When container is ready
    Then container log should contain :8080/services/rest/server

  Scenario: Don't configure kie server to use LDAP authentication
    When container is ready
    Then container log should contain AUTH_LDAP_URL not set. Skipping LDAP integration...
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <login-module code="LdapExtended"

  # https://issues.jboss.org/browse/RHPAM-891
  # https://issues.jboss.org/browse/RHPAM-1135
  Scenario: Check custom users are properly configured
    When container is started with env
      | variable                   | value         |
      | KIE_ADMIN_USER             | customAdm     |
      | KIE_ADMIN_PWD              | custom" Adm!0 |
      | KIE_MAVEN_USER             | customMvn     |
      | KIE_MAVEN_PWD              | custom" Mvn!0 |
      | KIE_SERVER_CONTROLLER_USER | customCtl     |
      | KIE_SERVER_CONTROLLER_PWD  | custom" Ctl!0 |
      | KIE_SERVER_USER            | customExe     |
      | KIE_SERVER_PWD             | custom" Exe!0 |
    Then file /opt/eap/standalone/configuration/application-users.properties should contain customAdm=a4d41e50a4ae17a50c1ceabe21e41a80
     And file /opt/eap/standalone/configuration/application-roles.properties should contain customAdm=kie-server,rest-all,admin,kiemgmt,Administrators
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customMvn
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customMvn
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customCtl
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customCtl
     And file /opt/eap/standalone/configuration/application-users.properties should contain customExe=d2d5d854411231a97fdbf7fe6f91a786
     And file /opt/eap/standalone/configuration/application-roles.properties should contain customExe=kie-server,rest-all,guest

  Scenario: Check custom users are properly configured
    When container is started with env
      | variable                   | value         |
      | KIE_ADMIN_USER             | customAdm     |
      | KIE_ADMIN_PWD              | custom" Adm!0 |
      | KIE_ADMIN_ROLES            | role1,admin2  |
      | KIE_SERVER_USER            | customExe     |
      | KIE_SERVER_PWD             | custom" Exe!0 |
      | KIE_SERVER_ROLES           | role2         |
    Then file /opt/eap/standalone/configuration/application-users.properties should contain customAdm=a4d41e50a4ae17a50c1ceabe21e41a80
    And file /opt/eap/standalone/configuration/application-roles.properties should contain customAdm=role1,admin2
    And file /opt/eap/standalone/configuration/application-users.properties should contain customExe=d2d5d854411231a97fdbf7fe6f91a786
    And file /opt/eap/standalone/configuration/application-roles.properties should contain customExe=role2

  # https://issues.jboss.org/browse/RHPAM-891
  Scenario: Check default users are properly configured
    When container is ready
    Then file /opt/eap/standalone/configuration/application-users.properties should contain adminUser=de3155e1927c6976555925dec24a53ac
     And file /opt/eap/standalone/configuration/application-roles.properties should contain adminUser=kie-server,rest-all,admin,kiemgmt,Administrators
     And file /opt/eap/standalone/configuration/application-users.properties should not contain mavenUser
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain mavenUser
     And file /opt/eap/standalone/configuration/application-users.properties should not contain controllerUser
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain controllerUser
     And file /opt/eap/standalone/configuration/application-users.properties should contain executionUser=69ea96114cd41afa6a9d5be2e1e0531e
     And file /opt/eap/standalone/configuration/application-roles.properties should contain executionUser=kie-server,rest-all,guest

  # https://issues.jboss.org/browse/CLOUD-1145 - base test
  Scenario: Check custom war file was successfully deployed via CUSTOM_INSTALL_DIRECTORIES
    Given s2i build https://github.com/jboss-openshift/openshift-examples.git from custom-install-directories
      | variable                   | value    |
      | CUSTOM_INSTALL_DIRECTORIES | custom   |
    Then file /opt/eap/standalone/deployments/node-info.war should exist

  Scenario: Verify the KIE_SERVER_BYPASS_AUTH_USER configuration
    When container is started with env
      | variable                    | value    |
      | KIE_SERVER_BYPASS_AUTH_USER | true     |
    Then container log should contain -Dorg.kie.server.bypass.auth.user=true

  Scenario: Verify the KIE_SERVER_CONTROLLER_TOKEN configuration
    When container is started with env
      | variable                    | value    |
      | KIE_SERVER_CONTROLLER_TOKEN | mytoken  |
    Then container log should contain -Dorg.kie.server.controller.token=mytoken

  Scenario: Verify the KIE_SERVER_DOMAIN default configuration
    When container is ready
    Then container log should contain -Dorg.kie.server.domain=other

  Scenario: Verify the KIE_SERVER_DOMAIN configuration
    When container is started with env
      | variable          | value    |
      | KIE_SERVER_DOMAIN | mydomain  |
    Then container log should contain -Dorg.kie.server.domain=mydomain

  Scenario: Verify the KIE_SERVER_TOKEN configuration
    When container is started with env
      | variable         | value             |
      | KIE_SERVER_TOKEN | mykieservertoken  |
    Then container log should contain -Dorg.kie.server.token=mykieservertoken

  Scenario: test DROOLS_SERVER_FILTER_CLASSES configuration
    When container is started with env
      | variable                     | value |
      | DROOLS_SERVER_FILTER_CLASSES | false |
    Then container log should contain -Dorg.drools.server.filter.classes=false

  Scenario: test DROOLS_SERVER_FILTER_CLASSES default configuration
    When container is ready
    Then container log should contain -Dorg.drools.server.filter.classes=true

