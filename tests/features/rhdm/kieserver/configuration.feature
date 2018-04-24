@rhdm-7/rhdm70-kieserver-openshift
Feature: RHDM 7 KIE Server configuration tests

  # https://issues.jboss.org/browse/RHPAM-846
  Scenario: Check jbpm is not enabled in RHDM 7
    When container is ready
    Then container log should contain -Dorg.jbpm.server.ext.disabled=true
     And container log should not contain -Dorg.jbpm.ejb.timer.tx=true

