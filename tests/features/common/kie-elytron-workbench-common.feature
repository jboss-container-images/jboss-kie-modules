@ibm-bamoe/bamoe-businesscentral-rhel8
@ibm-bamoe/bamoe-businesscentral-monitoring-rhel8
Feature: KIE specific elytron configuration

  Scenario: test if elytron KieRealm is correctly added with custom filesystem location
    When container is started with env
      | variable            | value         |
      | KIE_ELYTRON_FS_PATH | /opt/kie/test |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value KieFsRealm on XPath //*[local-name()='filesystem-realm']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value /opt/kie/test on XPath //*[local-name()='filesystem-realm']/*[local-name()='file']/@path
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ApplicationDomain on XPath //*[local-name()='security']/@elytron-domain
    And file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/jboss-web.xml should not contain <security-domain>other</security-domain>
    And container log should contain -Dorg.uberfire.ext.security.management.wildfly.filesystem.folder-path=/opt/kie/test
    And container log should contain -Dorg.uberfire.ext.security.management.wildfly.cli.folderPath=/opt/kie/test

  Scenario: test if elytron KieRealm is correctly added with default filesystem location
    When container is started with env
      | variable     | value        |
      | SCRIPT_DEBUG | true         |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value KieFsRealm on XPath //*[local-name()='filesystem-realm']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value /opt/kie/data/kie-fs-realm-users on XPath //*[local-name()='filesystem-realm']/*[local-name()='file']/@path
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ApplicationDomain on XPath //*[local-name()='security']/@elytron-domain
    And file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/jboss-web.xml should not contain <security-domain>other</security-domain>
    And container log should contain -Dorg.uberfire.ext.security.management.wildfly.filesystem.folder-path=/opt/kie/data/kie-fs-realm-users
    And container log should contain -Dorg.uberfire.ext.security.management.wildfly.cli.folderPath=/opt/kie/data/kie-fs-realm-users

  Scenario: test if the kie_git_config file is correctly generated
    When container is started with env
      | variable       | value        |
      | SSO_URL        | https://test |
      | SSO_SECRET     | web-secret   |
      | SSO_REALM      | sso-realm    |
    Then file /opt/eap/kie_git_config.json should contain "realm": "sso-realm"
    And file /opt/eap/kie_git_config.json should contain "auth-server-url": "https://test"
    And file /opt/eap/kie_git_config.json should contain "ssl-required": "external"
    And file /opt/eap/kie_git_config.json should contain "resource": "kie-git"
    And file /opt/eap/kie_git_config.json should contain "credentials"
    And file /opt/eap/kie_git_config.json should contain "secret": "web-secret"

  Scenario: test if the kie_git_config file is correctly generated with public key
    When container is started with env
      | variable       | value        |
      | SSO_URL        | https://test |
      | SSO_SECRET     | web-secret   |
      | SSO_REALM      | sso-realm    |
      | SSO_PUBLIC_KEY | random-key   |
    Then file /opt/eap/kie_git_config.json should contain "realm": "sso-realm",
    And file /opt/eap/kie_git_config.json should contain "realm-public-key": "random-key",
    And file /opt/eap/kie_git_config.json should contain "auth-server-url": "https://test",
    And file /opt/eap/kie_git_config.json should contain "ssl-required": "external",
    And file /opt/eap/kie_git_config.json should contain "resource": "kie-git",
    And file /opt/eap/kie_git_config.json should contain "credentials": {
    And file /opt/eap/kie_git_config.json should contain "secret": "web-secret"