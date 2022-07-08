@ibm-bamoe/bamoe-businesscentral-rhel8
Feature: Decision/Business Central authoring features

  Scenario: Configure GIT_HOOKS_DIR and check for directory existence
    When container is started with env
      | variable      | value          |
      | GIT_HOOKS_DIR | /opt/kie/data/git/hooks |
    Then container log should contain GIT_HOOKS_DIR directory "/opt/kie/data/git/hooks" created.
    And file /opt/kie/data/git/hooks should exist and be a directory

  Scenario: RHPAM-3299 BC image not using PV to store its local .m2/repository with default m2 repo
    When container is started with env
      | variable               | value     |
      | KIE_PERSIST_MAVEN_REPO | true      |
    Then container log should contain M2 repository is set to /opt/kie/data/m2
     And file /home/jboss/.m2/settings.xml should contain  <localRepository>/opt/kie/data/m2</localRepository>

  Scenario: RHPAM-3299 BC image not using PV to store its local .m2/repository with custom m2 repo
    When container is started with env
      | variable               | value     |
      | KIE_PERSIST_MAVEN_REPO | true      |
      | KIE_M2_REPO_DIR        | /tmp/test |
    Then container log should contain M2 repository is set to /tmp/test
     And file /home/jboss/.m2/settings.xml should contain  <localRepository>/tmp/test</localRepository>

  Scenario: RHPAM-3299 BC image not using PV to store its local .m2/repository - if MAVEN_LOCAL_REPO is set, the config should not happen
    When container is started with env
      | variable               | value          |
      | KIE_PERSIST_MAVEN_REPO | true           |
      | MAVEN_LOCAL_REPO       | /tmp/test/123  |
    Then container log should not contain M2 repository is set to /tmp/test/123
     And file /home/jboss/.m2/settings.xml should contain <localRepository>/tmp/test/123</localRepository>
     And container log should contain MAVEN_LOCAL_REPO is set to /tmp/test/123, if it needs to be persisted, make sure a Persistent Volume is mounted.

  Scenario: RHPAM-3594 Test if the org.kie.controller.ping.alive.disable is disabled when using the OpenShiftStartupStrategy
    When container is started with env
      | variable                                 | value  |
      | KIE_SERVER_CONTROLLER_OPENSHIFT_ENABLED  | true   |
    Then container log should contain -Dorg.kie.controller.ping.alive.disable=true
     And container log should contain -Dorg.kie.server.controller.openshift.enabled=true
     And container log should contain -Dorg.kie.server.controller.openshift.global.discovery.enabled=false
     And container log should contain -Dorg.kie.server.controller.openshift.prefer.kieserver.service=true
     And container log should contain -Dorg.kie.server.controller.template.cache.ttl=5000

  Scenario: RHPAM-3594 Test if the org.kie.controller.ping.alive.disable is disabled when NOT using the OpenShiftStartupStrategy
    When container is started with env
      | variable                                 | value  |
      | KIE_SERVER_CONTROLLER_OPENSHIFT_ENABLED  | false  |
    Then container log should not contain -Dorg.kie.controller.ping.alive.disable=true
     And container log should contain -Dorg.kie.server.controller.openshift.enabled=false
     And container log should contain -Dorg.kie.server.controller.openshift.global.discovery.enabled=false
     And container log should contain -Dorg.kie.server.controller.openshift.prefer.kieserver.service=true
     And container log should contain -Dorg.kie.server.controller.template.cache.ttl=5000

  Scenario: RHPAM-3594 Test if the org.kie.controller.ping.alive.disable with JAVA_OPTS_APPEND property
    When container is started with env
      | variable                                 | value                                        |
      | KIE_SERVER_CONTROLLER_OPENSHIFT_ENABLED  | false                                        |
      | JAVA_OPTS_APPEND                         | -Dorg.kie.controller.ping.alive.disable=true |
    Then container log should not contain -Dorg.kie.controller.ping.alive.disable=false
     And container log should contain -Dorg.kie.controller.ping.alive.disable=true

