@rhpam-7/rhpam71-businesscentral-monitoring-openshift
Feature: RHPAM Business Central Monitoring configuration tests

  # https://issues.jboss.org/browse/CLOUD-180
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain rhpam-7/rhpam71-businesscentral-monitoring-openshift image, version

  Scenario: Check for product and version environment variables
    When container is ready
    Then run sh -c 'echo $JBOSS_PRODUCT' in container and check its output for rhpam-businesscentral-monitoring
     And run sh -c 'echo $RHPAM_BUSINESS_CENTRAL_MONITORING_VERSION' in container and check its output for 7.1.0

  # https://issues.jboss.org/browse/RHPAM-891
  Scenario: Check default users are properly configured
    When container is ready
    Then file /opt/eap/standalone/configuration/application-users.properties should contain adminUser=de3155e1927c6976555925dec24a53ac
     And file /opt/eap/standalone/configuration/application-roles.properties should contain adminUser=kie-server,rest-all,admin,kiemgmt,Administrators
     And file /opt/eap/standalone/configuration/application-users.properties should not contain mavenUser
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain mavenUser
     And file /opt/eap/standalone/configuration/application-users.properties should contain controllerUser=b39c9321953da48d982c018bb131c4b0
     And file /opt/eap/standalone/configuration/application-roles.properties should contain controllerUser=kie-server,rest-all,guest
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
    Then file /opt/eap/standalone/configuration/application-users.properties should contain customAdm=a4d41e50a4ae17a50c1ceabe21e41a80
     And file /opt/eap/standalone/configuration/application-roles.properties should contain customAdm=kie-server,rest-all,admin,kiemgmt,Administrators
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customMvn
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customMvn
     And file /opt/eap/standalone/configuration/application-users.properties should contain customCtl=cc9f10a8ed20f1409b2282f4d5ca4d43
     And file /opt/eap/standalone/configuration/application-roles.properties should contain customCtl=kie-server,rest-all,guest
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customExe
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customExe

  # https://issues.jboss.org/browse/CLOUD-2221
  Scenario: Check KieLoginModule is configured
    When container is ready
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <login-module code="org.kie.security.jaas.KieLoginModule"
