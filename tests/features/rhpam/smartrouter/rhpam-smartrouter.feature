@rhpam-7/rhpam73-smartrouter-openshift
Feature: RHPAM Smart Router configuration tests

  # https://issues.jboss.org/browse/CLOUD-180
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain rhpam-7/rhpam73-smartrouter-openshift image, version

  Scenario: Check for product and version environment variables
    When container is ready
    Then run sh -c 'echo $JBOSS_PRODUCT' in container and check its output for rhpam-smartrouter
     And run sh -c 'echo $RHPAM_SMARTROUTER_VERSION' in container and check its output for 7.3

  # If KIE_SERVER_ROUTER_TLS_TEST is true the launch script will generate a certificate at /tmp/keystore.jks
  # with key alias "jboss" and password "mykeystorepass" and reset KIE_SERVER_ROUTER_TLS_KEYSTORE to /tmp/keystore.jks
  # This functionality is not available if KUBERNETES_SERVICE_HOST is set, i.e the container is running in OpenShift

  Scenario: Verify the smart router TLS configuration, no conf provided
    When container is ready
    Then container log should contain Missing value for TLS keystore path, alias, or password, skipping https setup
    And container log should match regex KieServerRouter started on.*9000 at
    And container log should not contain Container is in test mode and not in OpenShift, generating test certificate

  Scenario: Verify the smart router TLS configuration, test cert not generated and KIE_SERVER_ROUTER_TLS_KEYSTORE not found
    When container is started with env
      | variable                                 | value                            |
      | KIE_SERVER_ROUTER_TLS_TEST               | false                            |
      | KIE_SERVER_ROUTER_TLS_KEYSTORE           | /etc/cert/certificate            |
      | KIE_SERVER_ROUTER_TLS_KEYSTORE_KEYALIAS  | jboss                            |
      | KIE_SERVER_ROUTER_TLS_KEYSTORE_PASSWORD  | mykeystorepass                   |
    Then container log should contain Keystore file /etc/cert/certificate not found or not a regular file, skipping https setup
    And container log should match regex KieServerRouter started on.*9000 at
    And container log should not contain Container is in test mode and not in OpenShift, generating test certificate

  Scenario: Verify the smart router TLS configuration, test cert not generated because KUBERNETES_SERVICE_HOST defined
    When container is started with env
      | variable                                 | value                            |
      | KIE_SERVER_ROUTER_TLS_TEST               | true                             |
      | KUBERNETES_SERVICE_HOST                  | somevalue                        |
      | KIE_SERVER_ROUTER_TLS_KEYSTORE           | /etc/cert/certificate            |
      | KIE_SERVER_ROUTER_TLS_KEYSTORE_KEYALIAS  | jboss                            |
      | KIE_SERVER_ROUTER_TLS_KEYSTORE_PASSWORD  | mykeystorepass                   |
    Then container log should contain Keystore file /etc/cert/certificate not found or not a regular file, skipping https setup
    And container log should match regex KieServerRouter started on.*9000 at
    And container log should not contain Container is in test mode and not in OpenShift, generating test certificate

  Scenario: Verify the smart router TLS configuration, test cert not generated because keystore path exists
    When container is started with env
      | variable                                 | value                                      |
      | KIE_SERVER_ROUTER_TLS_TEST               | true                                       |
      | KIE_SERVER_ROUTER_TLS_KEYSTORE           | /opt/rhpam-smartrouter/openshift-launch.sh |
      | KIE_SERVER_ROUTER_TLS_KEYSTORE_KEYALIAS  | jboss                                      |
      | KIE_SERVER_ROUTER_TLS_KEYSTORE_PASSWORD  | mykeystorepass                             |
    Then container log should contain Unable to read TLS keystore, skipping https setup
    And container log should match regex KieServerRouter started on.*9000 at
    And container log should not contain Container is in test mode and not in OpenShift, generating test certificate

  Scenario: Verify the smart router TLS configuration, incorrect user
    When container is started with env
      | variable                                 | value                            |
      | KIE_SERVER_ROUTER_TLS_TEST               | true                             |
      | KIE_SERVER_ROUTER_TLS_KEYSTORE           | /etc/cert/certificate            |
      | KIE_SERVER_ROUTER_TLS_KEYSTORE_KEYALIAS  | thisiswrong                      |
      | KIE_SERVER_ROUTER_TLS_KEYSTORE_PASSWORD  | mykeystorepass                   |
    Then container log should contain Unable to read TLS keystore, skipping https setup
    And container log should match regex KieServerRouter started on.*9000 at
    And container log should contain Container is in test mode and not in OpenShift, generating test certificate

  Scenario: Verify the smart router TLS configuration, incorrect password
    When container is started with env
      | variable                                 | value                            |
      | KIE_SERVER_ROUTER_TLS_TEST               | true                             |
      | KIE_SERVER_ROUTER_TLS_KEYSTORE           | /etc/cert/certificate            |
      | KIE_SERVER_ROUTER_TLS_KEYSTORE_KEYALIAS  | jboss                            |
      | KIE_SERVER_ROUTER_TLS_KEYSTORE_PASSWORD  | thisiswrong                      |
    Then container log should contain Unable to read TLS keystore, skipping https setup
    And container log should match regex KieServerRouter started on.*9000 at
    And container log should contain Container is in test mode and not in OpenShift, generating test certificate

  Scenario: Verify the smart router TLS configuration, everything correct
    When container is started with env
      | variable                                 | value                            |
      | KIE_SERVER_ROUTER_TLS_TEST               | true                             |
      | KIE_SERVER_ROUTER_TLS_KEYSTORE           | /etc/cert/certificate            |
      | KIE_SERVER_ROUTER_TLS_KEYSTORE_KEYALIAS  | jboss                            |
      | KIE_SERVER_ROUTER_TLS_KEYSTORE_PASSWORD  | mykeystorepass                   |
    Then container log should match regex KieServerRouter started on.*9000 and .*9443 \(TLS\) at
    And container log should contain Container is in test mode and not in OpenShift, generating test certificate
