@rhdm-7/rhdm-kieserver-rhel8
Feature: RHDM KIE Server configuration tests

  # https://issues.jboss.org/browse/CLOUD-180
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain rhdm-7/rhdm-kieserver-rhel8 image, version

  Scenario: Check for product and version environment variables
    When container is ready
    Then run sh -c 'echo $JBOSS_PRODUCT' in container and check its output for rhdm-kieserver
     And run sh -c 'echo $RHDM_KIESERVER_VERSION' in container and check its output for 7.11

  Scenario: deploys the hellorules example, then checks if it's deployed. Additionally test if the JAVA_OPTS_APPEND is used in the container verifier step
    Given s2i build https://github.com/jboss-container-images/rhdm-7-openshift-image from quickstarts/hello-rules/hellorules using master
      | variable                        | value                                                                                        |
      | KIE_SERVER_CONTAINER_DEPLOYMENT | rhdm-kieserver-hellorules=org.openshift.quickstarts:rhdm-kieserver-hellorules:1.6.0-SNAPSHOT |
      | JAVA_OPTS_APPEND                | -Djavax.net.ssl.trustStore=truststore.ts -Djavax.net.ssl.trustStorePassword=123456           |
      | SCRIPT_DEBUG                    | true                                                                                         |
    Then s2i build log should contain Attempting to verify kie server containers with 'java org.kie.server.services.impl.KieServerContainerVerifier  org.openshift.quickstarts:rhdm-kieserver-hellorules:1.6.0-SNAPSHOT'
    And s2i build log should contain java -Djavax.net.ssl.trustStore=truststore.ts -Djavax.net.ssl.trustStorePassword=123456 --add-modules

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

  Scenario: Check KIE_SERVER_JBPM_CLUSTER flag enabled
    When container is started with env
      | variable                        | value                |
      | JGROUPS_PING_PROTOCOL           | kubernetes.KUBE_PING |
      | KIE_SERVER_JBPM_CLUSTER         | true                 |
    Then container log should contain Kie Server's cluster for JBPM fail over enabled
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <cache-container name="jbpm">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <transport lock-timeout="60000"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <replicated-cache name="nodes">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <transaction mode="BATCH"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain </replicated-cache>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <replicated-cache name="jobs">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <transaction mode="BATCH"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain </replicated-cache>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain </cache-container>

  Scenario: Check KIE_SERVER_JBPM_CLUSTER flag disabled
    When container is started with env
      | variable                        | value                |
      | JGROUPS_PING_PROTOCOL           | kubernetes.KUBE_PING |
      | KIE_SERVER_JBPM_CLUSTER         | false                |
    Then container log should contain Kie Server's cluster for JBPM fail over disabled
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <cache-container name="jbpm">
    
  Scenario: Check jbpm cache if KIE_SERVER_JBPM_CLUSTER isn't present
    When container is started with env
      | variable                        | value                |
      | JGROUPS_PING_PROTOCOL           | kubernetes.KUBE_PING |
    Then container log should contain Kie Server's cluster for JBPM fail over disabled
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <cache-container name="jbpm">

