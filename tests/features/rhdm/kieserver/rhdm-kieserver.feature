@rhdm-7/rhdm71-kieserver-openshift
Feature: RHDM KIE Server configuration tests

  # https://issues.jboss.org/browse/CLOUD-180
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain rhdm-7/rhdm71-kieserver-openshift image, version

  Scenario: Check for product and version environment variables
    When container is ready
    Then run sh -c 'echo $JBOSS_PRODUCT' in container and check its output for rhdm-kieserver
     And run sh -c 'echo $RHDM_KIESERVER_VERSION' in container and check its output for 7.1.0

  # https://issues.jboss.org/browse/RHPAM-891
  Scenario: Check default users are properly configured
    When container is ready
    Then file /opt/eap/standalone/configuration/application-users.properties should contain adminUser=de3155e1927c6976555925dec24a53ac
     And file /opt/eap/standalone/configuration/application-roles.properties should contain adminUser=kie-server,rest-all,admin,kiemgmt,Administrators
     And file /opt/eap/standalone/configuration/application-users.properties should not contain mavenUser
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain mavenUser
     And file /opt/eap/standalone/configuration/application-users.properties should not contain controllerUser
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain controllerUser
     And file /opt/eap/standalone/configuration/application-users.properties should contain executionUser=69ea96114cd41afa6a9d5be2e1e0531e
     And file /opt/eap/standalone/configuration/application-roles.properties should contain executionUser=kie-server,rest-all,guest

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
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customCtl
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customCtl
     And file /opt/eap/standalone/configuration/application-users.properties should contain customExe=d2d5d854411231a97fdbf7fe6f91a786
     And file /opt/eap/standalone/configuration/application-roles.properties should contain customExe=kie-server,rest-all,guest

  Scenario: Test REST API is available and valid
    When container is started with env
      | variable         | value       |
      | KIE_SERVER_USER  | kieserver   |
      | KIE_SERVER_PWD   | kieserver1! |
    Then check that page is served
      | property        | value                 |
      | port            | 8080                  |
      | path            | /services/rest/server |
      | wait            | 60                    |
      | username        | kieserver             |
      | password        | kieserver1!           |
      | expected_phrase | SUCCESS               |

  # https://issues.jboss.org/browse/CLOUD-1145 - base test
  Scenario: Check custom war file was successfully deployed via CUSTOM_INSTALL_DIRECTORIES
    Given s2i build https://github.com/jboss-openshift/openshift-examples.git from custom-install-directories
      | variable   | value                    |
      | CUSTOM_INSTALL_DIRECTORIES | custom   |
    Then file /opt/eap/standalone/deployments/node-info.war should exist

  Scenario: deploys the hellorules example, then checks if it's deployed.
    Given s2i build https://github.com/jboss-container-images/rhdm-7-openshift-image from quickstarts/hello-rules/hellorules using rhdm71-dev
      | variable                        | value                                                                                        |
      | KIE_SERVER_CONTAINER_DEPLOYMENT | rhdm-kieserver-hellorules=org.openshift.quickstarts:rhdm-kieserver-hellorules:1.4.0-SNAPSHOT |
    Then container log should contain Container rhdm-kieserver-hellorules

  # https://issues.jboss.org/browse/RHPAM-846
  Scenario: Check jbpm is _not_ enabled in RHDM 7
    When container is ready
    Then container log should contain -Dorg.jbpm.server.ext.disabled=true
     And container log should not contain -Dorg.jbpm.ejb.timer.tx=true
