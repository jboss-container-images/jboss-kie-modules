@rhdm-7/rhdm71-decisioncentral-openshift @rhpam-7/rhpam71-businesscentral-openshift
Feature: Decision/Business Central authoring features

  Scenario: Configure GIT_HOOKS_DIR and check for directory existence
    When container is started with env
      | variable      | value          |
      | GIT_HOOKS_DIR | /opt/eap/standalone/data/kie/git/hooks |
    Then container log should contain GIT_HOOKS_DIR directory "/opt/eap/standalone/data/kie/git/hooks" created.
    And file /opt/eap/standalone/data/kie/git/hooks should exist and be a directory

