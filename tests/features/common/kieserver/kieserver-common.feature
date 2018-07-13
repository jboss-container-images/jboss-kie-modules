@rhdm-7/rhdm70-kieserver-openshift  @rhpam-7/rhpam70-kieserver-openshift
Feature: Kie Server common features

  Scenario: Check if kieserver mgmt is correctly set.
    When container is started with env
      | variable                   | value  |
      | KIE_SERVER_MGMT_DISABLED   | true   |
    Then container log should contain -Dorg.kie.server.mgmt.api.disabled=true

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

  Scenario: Configure kie server to use LDAP authentication
    When container is started with env
      | variable          | value     |
      | AUTH_LDAP_URL | test_url  |
    Then container log should contain AUTH_LDAP_URL is set to test_url. Added LdapExtended login-module
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <login-module code="LdapExtended"
