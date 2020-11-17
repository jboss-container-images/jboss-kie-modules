@rhpam-7/rhpam-process-migration-rhel8
Feature: RHPAM Process Migration tests

  Scenario: Test REST API is available and valid
    When container is ready
    Then check that page is served
      | property        | value         |
      | port            | 8080          |
      | path            | /health/live  |
      | expected_phrase | {"status":"UP", "checks":[]}       |

