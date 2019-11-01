@rhdm-7/rhdm-decisioncentral-rhel8 @rhpam-7/rhpam-businesscentral-rhel8
Feature: Decision/Business Central authoring features

  Scenario: Configure GIT_HOOKS_DIR and check for directory existence
    When container is started with env
      | variable      | value          |
      | GIT_HOOKS_DIR | /opt/kie/data/git/hooks |
    Then container log should contain GIT_HOOKS_DIR directory "/opt/kie/data/git/hooks" created.
    And file /opt/kie/data/git/hooks should exist and be a directory
