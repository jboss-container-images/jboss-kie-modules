@rhdm-7/rhdm70-decisioncentral-openshift
Feature: RHDM Decision Central configuration tests

  # https://issues.jboss.org/browse/CLOUD-180
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain rhdm-7/rhdm70-decisioncentral-openshift image, version

  Scenario: Check for product and version environment variables
    When container is ready
    Then run sh -c 'echo $JBOSS_PRODUCT' in container and check its output for rhdm-decisioncentral
     And run sh -c 'echo $RHDM_DECISION_CENTRAL_VERSION' in container and check its output for 7.0.1

  # https://issues.jboss.org/browse/RHPAM-891
  Scenario: Check default users are properly configured
    When container is ready
    Then file /opt/eap/standalone/configuration/application-users.properties should contain adminUser=de3155e1927c6976555925dec24a53ac
     And file /opt/eap/standalone/configuration/application-roles.properties should contain adminUser=kie-server,rest-all,admin,kiemgmt,Administrators
     And file /opt/eap/standalone/configuration/application-users.properties should contain mavenUser=99889a669f3bd83f6cde702673a029f7
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain mavenUser
     And file /opt/eap/standalone/configuration/application-users.properties should contain controllerUser=b39c9321953da48d982c018bb131c4b0
     And file /opt/eap/standalone/configuration/application-roles.properties should contain controllerUser=kie-server,rest-all,guest
     And file /opt/eap/standalone/configuration/application-users.properties should not contain executionUser
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain executionUser

  # https://issues.jboss.org/browse/RHPAM-891
  Scenario: Check custom users are properly configured
    When container is started with env
      | variable                   | value       |
      | KIE_ADMIN_USER             | customAdm   |
      | KIE_ADMIN_PWD              | customAdm!0 |
      | KIE_MAVEN_USER             | customMvn   |
      | KIE_MAVEN_PWD              | customMvn!0 |
      | KIE_SERVER_CONTROLLER_USER | customCtl   |
      | KIE_SERVER_CONTROLLER_PWD  | customCtl!0 |
      | KIE_SERVER_USER            | customExe   |
      | KIE_SERVER_PWD             | customExe!0 |
    Then file /opt/eap/standalone/configuration/application-users.properties should contain customAdm=05ad559f03f4a06845bf201990f6832f
     And file /opt/eap/standalone/configuration/application-roles.properties should contain customAdm=kie-server,rest-all,admin,kiemgmt,Administrators
     And file /opt/eap/standalone/configuration/application-users.properties should contain customMvn=9c434ec142d056848c0e7919e49e7e54
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customMvn
     And file /opt/eap/standalone/configuration/application-users.properties should contain customCtl=33a59d7b05c7b102d455d140b0507733
     And file /opt/eap/standalone/configuration/application-roles.properties should contain customCtl=kie-server,rest-all,guest
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customExe
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customExe

  # https://issues.jboss.org/browse/CLOUD-2221
  Scenario: Check KieLoginModule is _not_ configured
    When container is ready
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <login-module code="org.kie.security.jaas.KieLoginModule"
