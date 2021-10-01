@rhdm-7/rhdm-decisioncentral-rhel8
Feature: RHDM Decision Central configuration tests

  # https://issues.jboss.org/browse/CLOUD-180
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain rhdm-7/rhdm-decisioncentral-rhel8 image, version

  Scenario: Check for product and version environment variables
    When container is started with command bash
    Then run sh -c 'echo $JBOSS_PRODUCT' in container and check its output for rhdm-decisioncentral
     And run sh -c 'echo $RHDM_DECISION_CENTRAL_VERSION' in container and check its output for 7.13

  # https://issues.jboss.org/browse/CLOUD-2221
  Scenario: Check KieLoginModule is _not_ configured
    When container is ready
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <login-module code="org.kie.security.jaas.KieLoginModule"

  # https://issues.jboss.org/browse/RHDM-871
  Scenario: Check Workbench profile for rhdm
    When container is ready
    Then container log should contain -Dorg.kie.workbench.profile=FORCE_PLANNER_AND_RULES
