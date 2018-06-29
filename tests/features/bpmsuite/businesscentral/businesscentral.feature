@jboss-bpmsuite-7/bpmsuite70-businesscentral-openshift
Feature: BPM Suite Business Central tests

  # https://issues.jboss.org/browse/CLOUD-180
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain jboss-bpmsuite-7/bpmsuite70-businesscentral-openshift image, version

  Scenario: Check for product and version environment variables
    When container is ready
    Then run sh -c 'echo $JBOSS_PRODUCT' in container and check its output for bpmsuite-businesscentral
    And run sh -c 'echo $JBOSS_BPMSUITE_BUSINESS_CENTRAL_VERSION' in container and check its output for 7.0.0

  Scenario: Check if git hooks dir is configured
    When container is started with env
      | variable      | value   |
      | GIT_HOOKS_DIR | /opt/git/hooks |
    Then container log should contain -Dorg.uberfire.nio.git.hooks=/opt/git/hooks