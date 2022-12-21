@rhpam-7/rhpam-kieserver-rhel8
@rhpam-7/rhpam-businesscentral-rhel8
@rhpam-7/rhpam-businesscentral-monitoring-rhel8
@rhpam-7/rhpam-controller-rhel8
Feature: RHPAM and RHDM common tests

  Scenario: Ensure the maven 3.8+ is installed
    When container is started with command bash
    Then run sh -c '/usr/bin/mvn --version | grep  "Apache Maven"' in container and check its output contains Apache Maven 3.8
