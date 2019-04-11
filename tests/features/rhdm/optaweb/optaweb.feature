@rhdm-7/rhdm74-optaweb-employee-rostering-openshift
Feature: RHDM OptaWeb configuration tests

  Scenario: Verify OptaWeb configurations
    When container is started with env
      | variable                                            | value                       |
      | OPTAWEB_EMPLOYEE_ROSTERING_PERSISTENCE_DATASOURCE   | java:jboss/datasource/123   |
      | OPTAWEB_EMPLOYEE_ROSTERING_PERSISTENCE_DIALECT      | org.test.my.custom.Dialect  |
      | OPTAWEB_EMPLOYEE_ROSTERING_PERSISTENCE_HBM2DDL_AUTO | false                       |
      | OPTAWEB_GENERATOR_ZONE_ID                           | America/Sao_Paulo           |
    Then container log should contain -Dorg.optaweb.employeerostering.persistence.datasource=java:jboss/datasource/123
     And container log should contain -Dorg.optaweb.employeerostering.persistence.dialect=org.test.my.custom.Dialect
     And container log should contain -Dorg.optaweb.employeerostering.persistence.hbm2ddl.auto=false
     And container log should contain optaweb.generator.zoneId=America/Sao_Paulo
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <spec-descriptor-property-replacement>true</spec-descriptor-property-replacement>

  Scenario: Check if eap users are not being created if SSO is configured
    When container is started with env
      | variable        | value         |
      | SSO_URL         | http://url    |
      | KIE_ADMIN_USER  | customExe     |
      | KIE_ADMIN_PWD   | custom" Exe!0 |
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain customExe=d2d5d854411231a97fdbf7fe6f91a786
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customExe=kie-server,rest-all,user
     And container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain KIE_ADMIN_USER is set to customExe, make sure to configure this user with the provided password on the external auth provider with the roles kie-server,rest-all,admin,kiemgmt,Administrators

  Scenario: Check if eap users are not being created if LDAP is configured
    When container is started with env
      | variable        | value         |
      | AUTH_LDAP_URL   | ldap://url:389|
      | KIE_ADMIN_USER  | customExe     |
      | KIE_ADMIN_PWD   | custom" Exe!0 |
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain customExe=d2d5d854411231a97fdbf7fe6f91a786
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customExe=kie-server,rest-all,user
     And container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain KIE_ADMIN_USER is set to customExe, make sure to configure this user with the provided password on the external auth provider with the roles kie-server,rest-all,admin,kiemgmt,Administrators

  Scenario: Check if eap users are not being created if SSO is configured with no users env
    When container is started with env
      | variable                   | value         |
      | SSO_URL                    | http://url    |
    Then container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain Make sure to configure a ADMIN user to access the Business Central with the roles kie-server,rest-all,admin,kiemgmt,Administrators

  Scenario: Check if eap users are not being created if LDAP is configured with no users env
    When container is started with env
      | variable                   | value         |
      | AUTH_LDAP_URL              | ldap://url:389|
    Then container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain Make sure to configure a ADMIN user to access the Business Central with the roles kie-server,rest-all,admin,kiemgmt,Administrators
