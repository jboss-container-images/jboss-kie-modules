@rhpam-7/rhpam70-kieserver-openshift
Feature: RHPAM 7 KIE Server configuration tests

  # https://issues.jboss.org/browse/RHPAM-846
  Scenario: Check jbpm is enabled in RHPAM 7
    When container is started with env
      | variable                 | value |
      | JBPM_LOOP_LEVEL_DISABLED | true  |
    Then container log should not contain -Dorg.jbpm.server.ext.disabled=true
     And container log should contain -Dorg.jbpm.ejb.timer.tx=true
     And container log should contain -Djbpm.loop.level.disabled=true

