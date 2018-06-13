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
  
  Scenario: Don't configure kie server to use LDAP authentication
    When container is ready
    Then container log should contain KIE_AUTH_LDAP_URL not set. Skipping LDAP integration...
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <login-module code="LdapExtended"

  Scenario: Configure kie server to use LDAP authentication
    When container is started with env
      | variable          | value     |
      | KIE_AUTH_LDAP_URL | test_url  |
    Then container log should contain KIE_AUTH_LDAP_URL is set to test_url. Added LdapExtended login-module
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <login-module code="LdapExtended"