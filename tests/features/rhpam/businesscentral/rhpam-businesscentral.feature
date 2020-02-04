@rhpam-7/rhpam-businesscentral-rhel8
Feature: RHPAM Business Central configuration tests

  # https://issues.jboss.org/browse/CLOUD-180
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain rhpam-7/rhpam-businesscentral-rhel8 image, version

  Scenario: Check for product and version environment variables
    When container is ready
    Then run sh -c 'echo $JBOSS_PRODUCT' in container and check its output for rhpam-businesscentral
     And run sh -c 'echo $RHPAM_BUSINESS_CENTRAL_VERSION' in container and check its output for 7.7

  # https://issues.jboss.org/browse/RHPAM-891
  Scenario: Check default users are properly configured
    When container is ready
    Then file /opt/eap/standalone/configuration/application-users.properties should contain adminUser=de3155e1927c6976555925dec24a53ac
     And file /opt/eap/standalone/configuration/application-roles.properties should contain adminUser=kie-server,rest-all,admin,kiemgmt,Administrators

  # https://issues.jboss.org/browse/RHPAM-891
  # https://issues.jboss.org/browse/RHPAM-1135
  Scenario: Check custom users are properly configured
    When container is started with env
      | variable                   | value         |
      | KIE_ADMIN_USER             | customAdm     |
      | KIE_ADMIN_PWD              | custom" Adm!0 |
    Then file /opt/eap/standalone/configuration/application-users.properties should contain customAdm=b9dd729626b3df0d8070dc832dc1bf36
     And file /opt/eap/standalone/configuration/application-roles.properties should contain customAdm=kie-server,rest-all,admin,kiemgmt,Administrators

  # https://issues.jboss.org/browse/CLOUD-2221
  Scenario: Check KieLoginModule is configured
    When container is ready
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <login-module code="org.kie.security.jaas.KieLoginModule"

  # https://issues.jboss.org/browse/JBPM-7834
  # https://issues.jboss.org/projects/JBPM/issues/JBPM-8269
  Scenario: Check OpenShiftStartupStrategy is enabled in RHPAM 7
    When container is started with env
      | variable                                                 | value                     |
      | KIE_SERVER_CONTROLLER_OPENSHIFT_GLOBAL_DISCOVERY_ENABLED | true                      |
      | KIE_SERVER_CONTROLLER_OPENSHIFT_PREFER_KIESERVER_SERVICE | true                      |
      | KIE_SERVER_CONTROLLER_TEMPLATE_CACHE_TTL                 | 10000                     |
      | KIE_WORKBENCH_CONTROLLER_OPENSHIFT_ENABLED               | true                      |
    Then container log should contain -Dorg.kie.server.controller.openshift.global.discovery.enabled=true
     And container log should contain -Dorg.kie.server.controller.openshift.prefer.kieserver.service=true
     And container log should contain -Dorg.kie.server.controller.template.cache.ttl=10000
     And container log should contain -Dorg.kie.workbench.controller.openshift.enabled=true
     And container log should contain -Dorg.kie.controller.ping.alive.disable=true

  # https://issues.jboss.org/browse/RHDM-871
  Scenario: Check Workbench profile for rhpam
    When container is ready
    Then container log should contain -Dorg.kie.workbench.profile=FORCE_FULL

  # https://issues.jboss.org/browse/KIECLOUD-160
  Scenario: Check Workbench for Git http support
    When container is started with env
      | variable         | value       |
      | HOSTNAME_HTTP    | example.com |
    Then container log should contain -Dorg.uberfire.nio.git.https.enabled=false
     And container log should contain -Dorg.uberfire.nio.git.http.enabled=true
     And container log should contain -Dorg.uberfire.nio.git.http.hostname=example.com
     And container log should contain -Dorg.uberfire.nio.git.http.port=80
