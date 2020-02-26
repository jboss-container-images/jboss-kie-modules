@rhdm-7/rhdm-kieserver-rhel8
Feature: RHDM KIE Server configuration tests

  # https://issues.jboss.org/browse/CLOUD-180
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain rhdm-7/rhdm-kieserver-rhel8 image, version

  Scenario: Check for product and version environment variables
    When container is ready
    Then run sh -c 'echo $JBOSS_PRODUCT' in container and check its output for rhdm-kieserver
     And run sh -c 'echo $RHDM_KIESERVER_VERSION' in container and check its output for 7.8


  # KIECLOUD-11: temporarily ignore since Jenkins CI builds currently fail with this test, even though it passes when run at the command line
  @ignore
  Scenario: deploys the hellorules example, then checks if it's deployed.
    Given s2i build https://github.com/jboss-container-images/rhdm-7-openshift-image from quickstarts/hello-rules/hellorules using rhdm71-dev
      | variable                        | value                                                                                        |
      | KIE_SERVER_CONTAINER_DEPLOYMENT | rhdm-kieserver-hellorules=org.openshift.quickstarts:rhdm-kieserver-hellorules:1.4.0-SNAPSHOT |
    Then container log should contain Container rhdm-kieserver-hellorules

  # https://issues.jboss.org/browse/RHPAM-846
  Scenario: Check jbpm is _not_ enabled in RHDM 7
    When container is ready
    Then container log should contain -Dorg.jbpm.server.ext.disabled=true
     And container log should contain -Dorg.jbpm.ui.server.ext.disabled=true
     And container log should contain -Dorg.jbpm.case.server.ext.disabled=true
     And container log should not contain -Dorg.jbpm.ejb.timer.tx=true

  Scenario: Check rhdm-kieserver extensions
    When container is ready
    Then container log should contain -Dorg.jbpm.server.ext.disabled=true -Dorg.jbpm.ui.server.ext.disabled=true -Dorg.jbpm.case.server.ext.disabled=true
