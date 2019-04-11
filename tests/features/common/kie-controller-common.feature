@rhdm-7/rhdm74-controller-openshift @rhpam-7/rhpam74-controller-openshift
Feature: KIE Controller configuration common tests

    # https://issues.jboss.org/browse/RHPAM-891
  Scenario: Check default users are properly configured
    When container is ready
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain adminUser
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain adminUser
     And file /opt/eap/standalone/configuration/application-users.properties should not contain mavenUser
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain mavenUser
     And file /opt/eap/standalone/configuration/application-users.properties should contain controllerUser=b39c9321953da48d982c018bb131c4b0
     And file /opt/eap/standalone/configuration/application-roles.properties should contain controllerUser=kie-server,rest-all,user
     And file /opt/eap/standalone/configuration/application-users.properties should not contain executionUser
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain executionUser

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
      | KIE_SERVER_TOKEN           | token         |
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain customAdm
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customAdm
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customMvn
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customMvn
     And file /opt/eap/standalone/configuration/application-users.properties should contain customCtl=cc9f10a8ed20f1409b2282f4d5ca4d43
     And file /opt/eap/standalone/configuration/application-roles.properties should contain customCtl=kie-server,rest-all,user
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customExe
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customExe
     And container log should contain -Dorg.kie.server.token=token

  Scenario: Check if eap users are not being created if SSO is configured
    When container is started with env
      | variable                   | value         |
      | SSO_URL                    | http://url    |
      | KIE_SERVER_CONTROLLER_USER | customCtl     |
      | KIE_SERVER_CONTROLLER_PWD  | custom" Ctl!0 |
      | KIE_SERVER_USER            | customExe     |
      | KIE_SERVER_PWD             | custom" Exe!0 |
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain customCtl
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customCtl
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customExe=d2d5d854411231a97fdbf7fe6f91a786
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customExe=kie-server,rest-all,user
     And container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain KIE_SERVER_USER is set to customExe, make sure to configure this user with the provided password on the external auth provider with the roles kie-server,rest-all,user
     And container log should contain KIE_SERVER_CONTROLLER_USER is set to customCtl, make sure to configure this user with the provided password on the external auth provider with the roles kie-server,rest-all,user

  Scenario: Check if eap users are not being created if LDAP is configured
    When container is started with env
      | variable                   | value         |
      | AUTH_LDAP_URL              | ldap://url:389|
      | KIE_SERVER_CONTROLLER_USER | customCtl     |
      | KIE_SERVER_CONTROLLER_PWD  | custom" Ctl!0 |
      | KIE_SERVER_USER            | customExe     |
      | KIE_SERVER_PWD             | custom" Exe!0 |
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain customCtl
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customCtl
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customExe=d2d5d854411231a97fdbf7fe6f91a786
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customExe=kie-server,rest-all,user
     And container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain KIE_SERVER_USER is set to customExe, make sure to configure this user with the provided password on the external auth provider with the roles kie-server,rest-all,user
     And container log should contain KIE_SERVER_CONTROLLER_USER is set to customCtl, make sure to configure this user with the provided password on the external auth provider with the roles kie-server,rest-all,user

  Scenario: Check if eap users are not being created if SSO is configured with no users env
    When container is started with env
      | variable                   | value         |
      | SSO_URL                    | http://url    |
    Then container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain Make sure to configure the KIE_SERVER_CONTROLLER_USER user to interact with KIE Server rest api with the roles kie-server,rest-all,user
     And container log should contain Make sure to configure the KIE_SERVER_USER user to interact with KIE Server rest api with the roles kie-server,rest-all,user

  Scenario: Check if eap users are not being created if LDAP is configured with no users env
    When container is started with env
      | variable                   | value         |
      | AUTH_LDAP_URL              | ldap://url:389|
    Then container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain Make sure to configure the KIE_SERVER_CONTROLLER_USER user to interact with KIE Server rest api with the roles kie-server,rest-all,user
     And container log should contain Make sure to configure the KIE_SERVER_USER user to interact with KIE Server rest api with the roles kie-server,rest-all,user
