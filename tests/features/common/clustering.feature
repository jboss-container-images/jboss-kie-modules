@rhpam-7/rhpam76-businesscentral-openshift @rhpam-7/rhpam76-businesscentral-monitoring-openshift @rhdm-7/rhdm76-decisioncentral-openshift
Feature: RHPAM RHDM Workbench clustering configuration

  Scenario: HA will not be configured
    When container is ready
    Then container log should contain JGROUPS_PING_PROTOCOL not set, HA will not be available.

  Scenario: HA missing configuration
    When container is started with env
      | variable                        | value                 |
      | JGROUPS_PING_PROTOCOL           | openshift.DNS_PING    |
      | OPENSHIFT_DNS_PING_SERVICE_NAME | ping                  |
      | OPENSHIFT_DNS_PING_SERVICE_PORT | 8888                  |
    Then container log should contain OpenShift DNS_PING protocol envs set, verifying other needed envs for HA setup. Using openshift.DNS_PING
     And container log should contain HA envs not set, HA will not be configured.

  Scenario: Elastic HA default configuration
    When container is started with env
      | variable                        | value                 |
      | JGROUPS_PING_PROTOCOL           | openshift.DNS_PING    |
      | OPENSHIFT_DNS_PING_SERVICE_NAME | ping                  |
      | OPENSHIFT_DNS_PING_SERVICE_PORT | 8888                  |
      | APPFORMER_ELASTIC_HOST          | 10.10.10.10           |
      | APPFORMER_JMS_BROKER_USERNAME   | brokerUser            |
      | APPFORMER_JMS_BROKER_PASSWORD   | brokerPwd             |
      | APPFORMER_JMS_BROKER_ADDRESS    | 11.11.11.11           |
      | APPFORMER_JMS_BROKER_PORT       | 8885                  |
    Then container log should contain -Dappformer-cluster=true
     And container log should contain -Dappformer-jms-connection-mode=REMOTE
     And container log should contain -Dappformer-jms-url=tcp://11.11.11.11:61616
     And container log should contain -Dappformer-jms-username=brokerUser
     And container log should contain -Dappformer-jms-password=brokerPwd
     And container log should contain -Des.set.netty.runtime.available.processors=false
     And container log should contain -Dorg.appformer.ext.metadata.index=elastic
     And container log should contain -Dorg.appformer.ext.metadata.elastic.host=10.10.10.10
     And container log should contain -Dorg.appformer.ext.metadata.elastic.port=9300
     And container log should contain -Dorg.appformer.ext.metadata.elastic.cluster=kie-cluster
     And container log should contain -Dorg.appformer.ext.metadata.elastic.retries=10

  Scenario: Elastic HA custom configuration
    When container is started with env
      | variable                        | value                 |
      | JGROUPS_PING_PROTOCOL           | openshift.DNS_PING    |
      | OPENSHIFT_DNS_PING_SERVICE_NAME | ping                  |
      | OPENSHIFT_DNS_PING_SERVICE_PORT | 8888                  |
      | APPFORMER_ELASTIC_HOST          | 10.10.10.10           |
      | APPFORMER_JMS_BROKER_USERNAME   | brokerUser            |
      | APPFORMER_JMS_BROKER_PASSWORD   | brokerPwd             |
      | APPFORMER_JMS_BROKER_ADDRESS    | 11.11.11.11           |
      | APPFORMTER_JMS_BROKER_PORT      | 5000                  |
      | APPFORMER_ELASTIC_PORT          | 9000                  |
      | APPFORMER_ELASTIC_CLUSTER_NAME  | my-custom-cluster     |
      | APPFORMER_ELASTIC_RETRIES       | 59                    |
    Then container log should contain -Dappformer-cluster=true
     And container log should contain -Dappformer-jms-connection-mode=REMOTE
     And container log should contain -Dappformer-jms-url=tcp://11.11.11.11:5000?ha=true&retryInterval=1000&retryIntervalMultiplier=1.0&reconnectAttempts=-1
     And container log should contain -Dappformer-jms-username=brokerUser
     And container log should contain -Dappformer-jms-password=brokerPwd
     And container log should contain -Des.set.netty.runtime.available.processors=false
     And container log should contain -Dorg.appformer.ext.metadata.index=elastic
     And container log should contain -Dorg.appformer.ext.metadata.elastic.host=10.10.10.10
     And container log should contain -Dorg.appformer.ext.metadata.elastic.port=9000
     And container log should contain -Dorg.appformer.ext.metadata.elastic.cluster=my-custom-cluster
     And container log should contain -Dorg.appformer.ext.metadata.elastic.retries=59

  Scenario: Elastic HA custom configuration with custom jms params
    When container is started with env
      | variable                        | value                 |
      | JGROUPS_PING_PROTOCOL           | openshift.DNS_PING    |
      | OPENSHIFT_DNS_PING_SERVICE_NAME | ping                  |
      | OPENSHIFT_DNS_PING_SERVICE_PORT | 8888                  |
      | APPFORMER_ELASTIC_HOST          | 10.10.10.10           |
      | APPFORMER_JMS_BROKER_USER       | brokerUser            |
      | APPFORMER_JMS_BROKER_PASSWORD   | brokerPwd             |
      | APPFORMER_JMS_BROKER_ADDRESS    | 11.11.11.11           |
      | APPFORMTER_JMS_BROKER_PORT      | 5000                  |
      | APPFORMER_ELASTIC_PORT          | 9000                  |
      | APPFORMER_ELASTIC_CLUSTER_NAME  | my-custom-cluster     |
      | APPFORMER_ELASTIC_RETRIES       | 59                    |
      | APPFORMER_JMS_CONNECTION_PARAMS | paramX=test2          |
    Then container log should contain -Dappformer-cluster=true
     And container log should contain -Dappformer-jms-connection-mode=REMOTE
     And container log should contain -Dappformer-jms-url=tcp://11.11.11.11:5000?paramX=test2
     And container log should contain -Dappformer-jms-username=brokerUser
     And container log should contain -Dappformer-jms-password=brokerPwd
     And container log should contain -Des.set.netty.runtime.available.processors=false
     And container log should contain -Dorg.appformer.ext.metadata.index=elastic
     And container log should contain -Dorg.appformer.ext.metadata.elastic.host=10.10.10.10
     And container log should contain -Dorg.appformer.ext.metadata.elastic.port=9000
     And container log should contain -Dorg.appformer.ext.metadata.elastic.cluster=my-custom-cluster
     And container log should contain -Dorg.appformer.ext.metadata.elastic.retries=59

  Scenario: Infinispan HA default configuration
    When container is started with env
      | variable                        | value              |
      | JGROUPS_PING_PROTOCOL           | openshift.DNS_PING |
      | OPENSHIFT_DNS_PING_SERVICE_NAME | ping               |
      | OPENSHIFT_DNS_PING_SERVICE_PORT | 8888               |
      | APPFORMER_INFINISPAN_HOST       | 10.10.10.10        |
      | APPFORMER_INFINISPAN_USERNAME   | requiredUser       |
      | APPFORMER_INFINISPAN_PASSWORD   | requiredPwd        |
      | APPFORMER_JMS_BROKER_USERNAME   | brokerUser         |
      | APPFORMER_JMS_BROKER_PASSWORD   | brokerPwd          |
      | APPFORMER_JMS_BROKER_ADDRESS    | 11.11.11.11        |
      | APPFORMER_JMS_BROKER_PORT       | 8885               |
    Then container log should contain -Dappformer-cluster=true
     And container log should contain -Dappformer-jms-connection-mode=REMOTE
     And container log should contain -Dappformer-jms-url=tcp://11.11.11.11:61616
     And container log should contain -Dappformer-jms-username=brokerUser
     And container log should contain -Dappformer-jms-password=brokerPwd
     And container log should contain -Dorg.appformer.ext.metadata.index=infinispan
     And container log should contain -Dorg.appformer.ext.metadata.infinispan.host=10.10.10.10
     And container log should contain -Dorg.appformer.ext.metadata.infinispan.port=11222
     And container log should contain -Dorg.appformer.ext.metadata.infinispan.username=requiredUser
     And container log should contain -Dorg.appformer.ext.metadata.infinispan.password=requiredPwd
     And container log should contain -Dorg.appformer.ext.metadata.infinispan.realm=ApplicationRealm
     And container log should not contain -Dorg.appformer.ext.metadata.infinispan.sasl.qop=
     And container log should not contain -Dorg.appformer.ext.metadata.infinispan.server.name=

  Scenario: Infinispan HA custom configuration
    When container is started with env
      | variable                         | value              |
      | JGROUPS_PING_PROTOCOL            | openshift.DNS_PING |
      | OPENSHIFT_DNS_PING_SERVICE_NAME  | ping               |
      | OPENSHIFT_DNS_PING_SERVICE_PORT  | 8888               |
      | APPFORMER_INFINISPAN_HOST        | 10.10.10.10        |
      | APPFORMER_INFINISPAN_PORT        | 11333              |
      | APPFORMER_INFINISPAN_USERNAME    | customUser         |
      | APPFORMER_INFINISPAN_PASSWORD    | customPassword     |
      | APPFORMER_INFINISPAN_REALM       | CustomRealm        |
      | APPFORMER_JMS_BROKER_USERNAME    | brokerUser         |
      | APPFORMER_JMS_BROKER_PASSWORD    | brokerPwd          |
      | APPFORMER_JMS_BROKER_ADDRESS     | 11.11.11.11        |
      | APPFORMTER_JMS_BROKER_PORT       | 5000               |
      | APPFORMER_INFINISPAN_SASL_QOP    | auth               |
      | APPFORMER_INFINISPAN_SERVER_NAME | jdg-server         |
    Then container log should contain -Dappformer-cluster=true
     And container log should contain -Dappformer-jms-connection-mode=REMOTE
     And container log should contain -Dappformer-jms-url=tcp://11.11.11.11:5000?ha=true&retryInterval=1000&retryIntervalMultiplier=1.0&reconnectAttempts=-1
     And container log should contain -Dappformer-jms-username=brokerUser
     And container log should contain -Dappformer-jms-password=brokerPwd
     And container log should contain -Dorg.appformer.ext.metadata.index=infinispan
     And container log should contain -Dorg.appformer.ext.metadata.infinispan.host=10.10.10.10
     And container log should contain -Dorg.appformer.ext.metadata.infinispan.port=11333
     And container log should contain -Dorg.appformer.ext.metadata.infinispan.username=customUser
     And container log should contain -Dorg.appformer.ext.metadata.infinispan.password=customPassword
     And container log should contain -Dorg.appformer.ext.metadata.infinispan.realm=CustomRealm
     And container log should contain -Dorg.appformer.ext.metadata.infinispan.sasl.qop=auth
     And container log should contain -Dorg.appformer.ext.metadata.infinispan.server.name=jdg-server
