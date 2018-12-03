@rhdm-7/rhdm72-optaweb-employee-rostering-openshift
Feature: RHDM OptaWeb configuration tests

  Scenario: Check jbpm is enabled in RHPAM 7
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
