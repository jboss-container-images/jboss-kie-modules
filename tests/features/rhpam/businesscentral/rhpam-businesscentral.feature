@rhpam-7/rhpam74-businesscentral-openshift
Feature: RHPAM Business Central configuration tests

  # https://issues.jboss.org/browse/CLOUD-180
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain rhpam-7/rhpam74-businesscentral-openshift image, version

  Scenario: Check for product and version environment variables
    When container is ready
    Then run sh -c 'echo $JBOSS_PRODUCT' in container and check its output for rhpam-businesscentral
     And run sh -c 'echo $RHPAM_BUSINESS_CENTRAL_VERSION' in container and check its output for 7.4

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
     And file /opt/eap/standalone/configuration/application-users.properties should contain customMvn=1977e1d207067592d9ec888cf860bae3
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customMvn
     And file /opt/eap/standalone/configuration/application-users.properties should contain customCtl=cc9f10a8ed20f1409b2282f4d5ca4d43
     And file /opt/eap/standalone/configuration/application-roles.properties should contain customCtl=kie-server,rest-all,guest
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customExe
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customExe

  # https://issues.jboss.org/browse/CLOUD-2221
  Scenario: Check KieLoginModule is configured
    When container is ready
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <login-module code="org.kie.security.jaas.KieLoginModule"

  # https://issues.jboss.org/browse/JBPM-7834
  Scenario: Check OpenShiftStartupStrategy is enabled in RHPAM 7
    When container is started with env
      | variable                                          | value                     |
      | KIE_CONTROLLER_OCP_ENABLED                        | true                      |
      | KIE_CONTROLLER_OPENSHIFT_PREFER_KIESERVER_SERVICE | false                     |
      | KIE_CONTROLLER_TEMPLATE_CACHE_TTL                 | 60000                     |
   Then container log should contain -Dorg.kie.workbench.controller.openshift.enabled=true
   Then container log should contain -Dorg.kie.server.controller.openshift.prefer.kieserver.service=false
   Then container log should contain -Dorg.kie.server.controller.template.cache.ttl=60000
