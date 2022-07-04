@rhpam-7/rhpam-process-migration-rhel8
Feature: IBM BAMOE Process Migration tests

  Scenario: Verify if all labels are correctly set on rhpam-process-migration-rhel8 image
    When container is started with command bash
    Then the image should contain label com.redhat.component with value rhpam-7-process-migration-rhel8-container
    And the image should contain label io.openshift.expose-services with value 8080:http
    And the image should contain label io.k8s.description with value Platform for running Red Hat Process Automation Manager Process Migration
    And the image should contain label io.k8s.display-name with value Red Hat Process Automation Manager Process Migration 8.0
    And the image should contain label io.openshift.tags with value javaee,rhpam,rhpam7,quarkus

  # https://issues.jboss.org/browse/CLOUD-180
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain rhpam-7/rhpam-process-migration-rhel8 image, version

  Scenario: Check for product and version environment variables
    When container is started with command bash
    Then run sh -c 'echo $JBOSS_PRODUCT' in container and check its output for rhpam-process-migration
    And run sh -c 'echo $RHPAM_PROCESS_MIGRATION_VERSION' in container and check its output for 8.0

  Scenario: Test health endpoints are available and valid
    When container is ready
    Then check that page is served
      | property        | value                           |
      | port            | 8080                            |
      | path            | /q/health/live                  |
      | wait            | 80                              |
      | request_method  | GET                             |
      | content_type    | application/json                |
      | request_body    | {"status": "UP", "checks": []}  |
    And check that page is served
      | property        | value                           |
      | port            | 8080                            |
      | path            | /q/health/ready                 |
      | wait            | 80                              |
      | request_method  | GET                             |
      | content_type    | application/json                |
      | request_body    | {"status": "UP", "checks": []}  |

  Scenario: Test REST API is accessible when providing users
    When container is started with env
    | variable             | value   |
    | JBOSS_KIE_ADMIN_USER | user123 |
    | JBOSS_KIE_ADMIN_PWD  | pwd123  |
    Then check that page is served
      | property             | value   |
      | port                 | 8080    |
      | username             | user123 |
      | password             | pwd123  |
      | expected_status_code | 200     |
    And file /opt/rhpam-process-migration/quarkus-app/config/application-users.properties should contain user123=pwd123
    And file /opt/rhpam-process-migration/quarkus-app/config/application-roles.properties should contain user123=admin

  Scenario: Test extra system properties are correctly added
    When container is started with env
      | variable         | value                                         |
      | JAVA_OPTS_APPEND | -Dsystem.prop.1=value1 -Dsystem.prop.2=value2 |
      | SCRIPT_DEBUG     | true                                          |
    Then container log should contain system.prop.1 = value1
     And container log should contain system.prop.2 = value2