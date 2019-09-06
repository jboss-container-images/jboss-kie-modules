@rhdm-7/rhdml76-decisioncentral-openshift @rhpam-7/rhpaml76-businesscentral-openshift
Feature: Decision/Business Central common features

  Scenario: Check custom users are properly configured
    When container is started with env
      | variable                    | value         |
      | KIE_ADMIN_USER              | customAdm     |
      | KIE_ADMIN_PWD               | custom" Adm!0 |
      | KIE_ADMIN_ROLES             | role1,admin2  |
      | KIE_MAVEN_USER              | customMvn     |
      | KIE_MAVEN_PWD               | custom        |
      | KIE_MAVEN_ROLES             | role1         |
      | KIE_SERVER_CONTROLLER_USER  | customCtl     |
      | KIE_SERVER_CONTROLLER_PWD   | custom" Ctl!0 |
      | KIE_SERVER_CONTROLLER_ROLES | role2         |
      | KIE_SERVER_USER             | customExe     |
      | KIE_SERVER_PWD              | custom" Exe!0 |
    Then file /opt/eap/standalone/configuration/application-users.properties should contain customAdm=a4d41e50a4ae17a50c1ceabe21e41a80
     And file /opt/eap/standalone/configuration/application-roles.properties should contain customAdm=role1,admin2
     And file /opt/eap/standalone/configuration/application-users.properties should contain customMvn
     And file /opt/eap/standalone/configuration/application-roles.properties should contain customMvn=role1
     And file /opt/eap/standalone/configuration/application-users.properties should contain customCtl
     And file /opt/eap/standalone/configuration/application-roles.properties should contain customCtl=role2
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customExe=d2d5d854411231a97fdbf7fe6f91a786
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customExe=kie-server,rest-all,user
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
      | KIE_MAVEN_USER              | customMvn     |
      | KIE_MAVEN_PWD               | custom        |
      | KIE_SERVER_CONTROLLER_USER  | customCtl     |
      | KIE_SERVER_CONTROLLER_PWD   | custom" Ctl!0 |
      | KIE_SERVER_CONTROLLER_ROLES | role2         |
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain customAdm=a4d41e50a4ae17a50c1ceabe21e41a80
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customAdm=role1,admin2
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customMvn
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customMvn=role1
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customCtl
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customCtl=role2
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customExe=d2d5d854411231a97fdbf7fe6f91a786
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customExe=kie-server,rest-all,user
     And container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain KIE_ADMIN_USER is set to customAdm, make sure to configure this user with the provided password on the external auth provider with the roles role1,admin2
     And container log should contain KIE_MAVEN_USER is set to customMvn, make sure to configure this user with the provided password on the external auth provider.
     And container log should contain KIE_SERVER_CONTROLLER_USER is set to customCtl, make sure to configure this user with the provided password on the external auth provider with the roles role2
     And container log should contain -Dorg.uberfire.ext.security.management.api.userManagementServices=KCAdapterUserManagementService
     And container log should contain -Dorg.uberfire.ext.security.management.keycloak.authServer=http://url
     And container log should contain -Dorg.jbpm.workbench.kie_server.keycloak=true

  Scenario: Check if eap users are not being created if LDAP is configured
    When container is started with env
      | variable                    | value         |
      | AUTH_LDAP_URL               | ldap://url:389|
      | KIE_ADMIN_USER              | customAdm     |
      | KIE_ADMIN_PWD               | custom" Adm!0 |
      | KIE_MAVEN_USER              | customMvn     |
      | KIE_MAVEN_PWD               | custom        |
      | KIE_SERVER_CONTROLLER_USER  | customCtl     |
      | KIE_SERVER_CONTROLLER_PWD   | custom" Ctl!0 |
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain customAdm=a4d41e50a4ae17a50c1ceabe21e41a80
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customAdm=role1,admin2
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customMvn
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customMvn=role1
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customCtl
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customCtl=role2
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customExe=d2d5d854411231a97fdbf7fe6f91a786
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customExe=kie-server,rest-all,user
     And container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain KIE_ADMIN_USER is set to customAdm, make sure to configure this user with the provided password on the external auth provider with the roles kie-server,rest-all,admin,kiemgmt,Administrators
     And container log should contain KIE_MAVEN_USER is set to customMvn, make sure to configure this user with the provided password on the external auth provider
     And container log should contain KIE_SERVER_CONTROLLER_USER is set to customCtl, make sure to configure this user with the provided password on the external auth provider with the roles kie-server,rest-all,user

  Scenario: Check if eap users are not being created if SSO is configured with no users env
    When container is started with env
      | variable                    | value         |
      | SSO_URL                     | http://url    |
    Then container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain Make sure to configure a ADMIN user to access the Business Central with the roles kie-server,rest-all,admin,kiemgmt,Administrators
     And container log should contain Make sure to configure the KIE_MAVEN_USER user to interact with Business Central embedded maven server
     And container log should contain Make sure to configure the KIE_SERVER_CONTROLLER_USER user to interact with KIE Server rest api with the roles kie-server,rest-all,user

  Scenario: Check if eap users are not being created if LDAP is configured with no users env
    When container is started with env
      | variable                    | value         |
      | AUTH_LDAP_URL               | ldap://url:389|
    Then container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain Make sure to configure a ADMIN user to access the Business Central with the roles kie-server,rest-all,admin,kiemgmt,Administrators
     And container log should contain Make sure to configure the KIE_MAVEN_USER user to interact with Business Central embedded maven server
     And container log should contain Make sure to configure the KIE_SERVER_CONTROLLER_USER user to interact with KIE Server rest api with the roles kie-server,rest-all,user

  # https://issues.jboss.org/browse/KIECLOUD-218
  # https://issues.jboss.org/browse/JBPM-8400
  Scenario: Check for kie keystore
    When container is ready
    Then container log should contain -Dkie.keystore.keyStoreURL=file:///opt/eap/standalone/configuration/kie-keystore.jceks
