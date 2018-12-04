@rhdm-7/rhdm72-decisioncentral-openshift @rhpam-7/rhpam72-businesscentral-openshift
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
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customExe=kie-server,rest-all,guest

