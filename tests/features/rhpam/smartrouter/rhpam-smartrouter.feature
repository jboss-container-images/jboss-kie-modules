@rhpam-7/rhpam-smartrouter-rhel8
Feature: RHPAM Smart Router configuration tests

  # https://issues.jboss.org/browse/CLOUD-180
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain rhpam-7/rhpam-smartrouter-rhel8 image, version

  Scenario: Check for product and version environment variables
    When container is ready
    Then run sh -c 'echo $JBOSS_PRODUCT' in container and check its output for rhpam-smartrouter
     And run sh -c 'echo $RHPAM_SMARTROUTER_VERSION' in container and check its output for 7.9

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

  Scenario: Verify if the properties were correctly set
    When container is started with env
      | variable                                  | value        |
      | SCRIPT_DEBUG                              | true         |
      | KIE_ADMIN_PWD                             | 123changeme  |
      | KIE_ADMIN_USER                            | userA        |
      | KIE_SERVER_CONTROLLER_HOST                | 10.1.1.190   |
      | KIE_SERVER_CONTROLLER_PORT                | 9005         |
      | KIE_SERVER_CONTROLLER_PROTOCOL            | http         |
      | KIE_SERVER_CONTROLLER_TOKEN               | tokenA       |
      | KIE_SERVER_ROUTER_HOST                    | routerHost   |
      | KIE_SERVER_ROUTER_ID                      | routerID     |
      | KIE_SERVER_ROUTER_NAME                    | routerName   |
      | KIE_SERVER_ROUTER_PORT                    | 10508        |
      | KIE_SERVER_ROUTER_PROTOCOL                | http         |
      | KIE_SERVER_ROUTER_URL_EXTERNAL            | externalURL  |
      | KIE_SERVER_ROUTER_REPO                    | routerRepo   |
      | KIE_SERVER_ROUTER_CONFIG_WATCHER_ENABLED  | true         |
    Then container log should contain org.kie.server.controller = http://10.1.1.190:9005
     And container log should contain org.kie.server.controller.user = userA
     And container log should contain org.kie.server.controller.pwd = 123changeme
     And container log should contain org.kie.server.controller.token = tokenA
     And container log should contain org.kie.server.router.host = routerHost
     And container log should contain org.kie.server.router.port = 10508
     And container log should contain org.kie.server.router.id = routerID
     And container log should contain org.kie.server.router.name = routerName
     And container log should contain org.kie.server.router.url.external = externalURL
     And container log should contain org.kie.server.router.repo = routerRepo
     And container log should contain org.kie.server.router.config.watcher.enabled = true

  Scenario: Verify if the properties were correctly set using CONTROLLER_SERVICE
    When container is started with env
      | variable                       | value        |
      | SCRIPT_DEBUG                   | true         |
      | KIE_SERVER_CONTROLLER_SERVICE  | SERVICE_ONE  |
      | SERVICE_ONE_SERVICE_HOST       | 10.1.1.12    |
      | SERVICE_ONE_SERVICE_PORT       | 10508        |
      | KIE_SERVER_CONTROLLER_PROTOCOL | http         |
    Then container log should contain -Dorg.kie.server.controller=http://10.1.1.12:10508

  Scenario: Verify if the properties were correctly set using DEFAULT MEM RATIO
    When container is started with args
      | arg       | value                                                    |
      | mem_limit | 1073741824                                               |
      | env_json  | {"JAVA_MAX_MEM_RATIO": 80, "JAVA_INITIAL_MEM_RATIO": 25} |
    Then container log should match regex -Xms205m
     And container log should match regex -Xmx819m
    
  Scenario: Verify if the DEFAULT MEM RATIO properties are overridden with different values
    When container is started with args
      | arg       | value                                                    |
      | mem_limit | 1073741824                                               |
      | env_json  | {"JAVA_MAX_MEM_RATIO": 50, "JAVA_INITIAL_MEM_RATIO": 10} |
    Then container log should match regex -Xms51m
     And container log should match regex -Xmx512m

  Scenario: Verify if the properties were correctly set when aren't passed
    When container is started with args
      | arg       | value                                                    |
      | mem_limit | 1073741824                                               |
    Then container log should match regex -Xms205m
     And container log should match regex -Xmx819m
