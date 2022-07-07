@ibm-bamoe/bamoe-kieserver-rhel8
Feature: KIE specific elytron configuration
  Scenario: test if elytron KieRealm is correctly added with default filesystem location
    When container is started with env
      | variable     | value |
      | SCRIPT_DEBUG | true  |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value KieFsRealm on XPath //*[local-name()='filesystem-realm']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value /opt/kie/data/kie-fs-realm-users on XPath //*[local-name()='filesystem-realm']/*[local-name()='file']/@path
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ApplicationDomain on XPath //*[local-name()='security']/@elytron-domain
    And file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/jboss-web.xml should not contain <security-domain>other</security-domain>
    And container log should contain -Dorg.kie.server.services.jbpm.security.filesystemrealm.folder-path=/opt/kie/data/kie-fs-realm-users

  Scenario: test if elytron KieRealm is correctly added with custom filesystem location
    When container is started with env
      | variable            | value         |
      | KIE_ELYTRON_FS_PATH | /opt/kie/test |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value KieFsRealm on XPath //*[local-name()='filesystem-realm']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value /opt/kie/test on XPath //*[local-name()='filesystem-realm']/*[local-name()='file']/@path
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ApplicationDomain on XPath //*[local-name()='security']/@elytron-domain
    And file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/jboss-web.xml should not contain <security-domain>other</security-domain>
    And container log should contain -Dorg.kie.server.services.jbpm.security.filesystemrealm.folder-path=/opt/kie/test

