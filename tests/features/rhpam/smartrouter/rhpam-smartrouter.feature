@rhpam-7/rhpam71-smartrouter-openshift
Feature: RHPAM Smart Router configuration tests

  # https://issues.jboss.org/browse/CLOUD-180
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain rhpam-7/rhpam71-smartrouter-openshift image, version

  Scenario: Check for product and version environment variables
    When container is ready
    Then run sh -c 'echo $JBOSS_PRODUCT' in container and check its output for rhpam-smartrouter
     And run sh -c 'echo $RHPAM_SMARTROUTER_VERSION' in container and check its output for 7.1.0
