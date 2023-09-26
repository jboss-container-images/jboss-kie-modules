@rhpam-7/rhpam-kieserver-rhel8
Feature: RHPAM KIE Server configuration tests

  # https://issues.jboss.org/browse/CLOUD-180
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain rhpam-7/rhpam-kieserver-rhel8 image, version

  Scenario: Check if the correct default maven profiles are activated
    When container is ready
    Then file /home/jboss/.m2/settings.xml should contain <activeProfile>securecentral</activeProfile>
    And file /home/jboss/.m2/settings.xml should contain <activeProfile>jboss-eap-repository</activeProfile>
    And file /home/jboss/.m2/settings.xml should contain <!-- ### active profiles ### -->

  Scenario: Check for product and version environment variables
    When container is started with command bash
    Then run sh -c 'echo $JBOSS_PRODUCT' in container and check its output for rhpam-kieserver
     And run sh -c 'echo $RHPAM_KIESERVER_VERSION' in container and check its output for 7.13

  Scenario: Check custom war file was successfully deployed via CUSTOM_INSTALL_DIRECTORIES
    Given s2i build https://github.com/jboss-openshift/openshift-examples.git from custom-install-directories
      | variable   | value                    |
      | CUSTOM_INSTALL_DIRECTORIES | custom   |
    Then file /opt/eap/standalone/deployments/node-info.war should exist

  Scenario: deploys the library example, then checks if it's deployed.
    Given s2i build https://github.com/jboss-container-images/rhpam-7-openshift-image from quickstarts/library-process/library using main
      | variable                        | value                                                                                    |
      | KIE_SERVER_CONTAINER_DEPLOYMENT | rhpam-kieserver-library=org.openshift.quickstarts:rhpam-kieserver-library:1.6.0-SNAPSHOT |
      | JAVA_OPTS_APPEND                | -Djavax.net.ssl.trustStore=truststore.ts -Djavax.net.ssl.trustStorePassword=123456       |
      | SCRIPT_DEBUG                    | true                                                                                     |
    Then s2i build log should contain Attempting to verify kie server containers with 'java org.kie.server.services.impl.KieServerContainerVerifier  org.openshift.quickstarts:rhpam-kieserver-library:1.6.0-SNAPSHOT'
    And s2i build log should contain java -Djavax.net.ssl.trustStore=truststore.ts -Djavax.net.ssl.trustStorePassword=123456 --add-modules
    And s2i build log should not contain And s2i build log should not contain java.lang.ClassNotFoundException: org.apache.maven.model.io.xpp3.MavenXpp3WriterEx

  # https://issues.jboss.org/browse/JBPM-7834
  Scenario: Check OpenShiftStartupStrategy is enabled in RHPAM 7
    When container is started with env
      | variable                    | value                     |
      | KIE_SERVER_STARTUP_STRATEGY | OpenShiftStartupStrategy  |
    Then container log should contain -Dorg.kie.server.startup.strategy=OpenShiftStartupStrategy

  Scenario: Check LocalContainersStartupStrategy is enabled in RHPAM 7
    When container is started with env
      | variable                    | value                     |
      | KIE_SERVER_STARTUP_STRATEGY | LocalContainersStartupStrategy  |
    Then container log should contain -Dorg.kie.server.startup.strategy=LocalContainersStartupStrategy

  # https://issues.jboss.org/browse/RHPAM-846
  Scenario: Check jbpm is enabled in RHPAM 7
    When container is started with env
      | variable                 | value |
      | JBPM_LOOP_LEVEL_DISABLED | true  |
    Then container log should not contain -Dorg.jbpm.server.ext.disabled=true
     And container log should contain -Djbpm.loop.level.disabled=true

  Scenario: Check for the default ejb timer's setup behavior
    When container is ready
    Then container log should contain EJB Timer will be auto configured if any datasource is configured via DB_SERVICE_PREFIX_MAPPING or DATASOURCES envs.

  Scenario: Check for the default ejb timer's setup behavior
    When container is started with env
      | variable                   | value     |
      | AUTO_CONFIGURE_EJB_TIMER   | false     |
    Then container log should not contain EJB Timer will be auto configured if any datasource is configured via DB_SERVICE_PREFIX_MAPPING or DATASOURCES envs.

  Scenario: Check jbpm ht configuration
    When container is started with env
      | variable                 | value       |
      | JBPM_HT_CALLBACK_CLASS   | my.db.class |
      | JBPM_HT_CALLBACK_METHOD  | db          |
      | JBPM_LOOP_LEVEL_DISABLED | true        |
    Then container log should contain -Dorg.jbpm.ht.callback=db
     And container log should contain -Dorg.jbpm.ht.custom.callback=my.db.class
     And container log should contain -Djbpm.loop.level.disabled=true

  # if this test fail, increase the cekit execution timeout, i.e. $ export CTF_WAIT_TIME=5; cekit....
  Scenario: Check for the Executor's retries configuration
    When container is started with env
      | variable               | value |
      | KIE_EXECUTOR_RETRIES   | 40    |
    Then container log should contain -Dorg.kie.executor.retry.count=40
     And container log should contain - Retries per Request: 40

  Scenario: KIECLOUD-122 - Enable JMS for RHDM and RHPAM, verify if the JMS is the default executor and jms transacted is false
    When container is ready
    Then container log should contain -Dorg.kie.executor.jms=true
     And container log should contain -Dorg.kie.executor.jms.queue=queue/KIE.SERVER.EXECUTOR
     And container log should contain -Dorg.kie.executor.jms.transacted=false
     And container log should contain Executor JMS based support successfully activated on queue ActiveMQQueue[jms.queue.KIE.SERVER.EXECUTOR]

  # if this test fail, increase the cekit execution timeout, i.e. $ export CTF_WAIT_TIME=5; cekit....
  Scenario: KIECLOUD-122 - Enable JMS for RHDM and RHPAM, verify if the JMS executor configuration
    When container is started with env
      | variable                           | value                             |
      | KIE_SERVER_JMS_QUEUE_EXECUTOR      | queue/KIE.SERVER.EXECUTOR.CUSTOM  |
      | KIE_SERVER_EXECUTOR_JMS_TRANSACTED | true                              |
    Then container log should contain -Dorg.kie.executor.jms=true
     And container log should contain -Dorg.kie.executor.jms.queue=queue/KIE.SERVER.EXECUTOR.CUSTOM
     And container log should contain -Dorg.kie.executor.jms.transacted=true
     And container log should contain Executor JMS based support successfully activated on queue ActiveMQQueue[jms.queue.KIE.SERVER.EXECUTOR]

  Scenario: RHPAM-640 - Verify if the Signal queue is correctly configured with default configuration
    When container is started with env
      | variable                           | value  |
      | KIE_SERVER_JMS_ENABLE_SIGNAL       | true   |
    Then container log should contain INFO Configuring Signal messaging queue
     And container log should contain Started message driven bean 'JMSSignalReceiver' with 'activemq-ra.rar' resource adapter

  Scenario: RHPAM-640 - Verify if the Signal queue is correctly configured with custom configuration
    When container is started with env
      | variable                      | value                        |
      | KIE_SERVER_JMS_ENABLE_SIGNAL  | true                         |
      | KIE_SERVER_JMS_QUEUE_SIGNAL   | queue/MY.CUSTOM.QUEUE.SIGNAL |
    Then container log should contain INFO Configuring Signal messaging queue
     And container log should contain Started message driven bean 'JMSSignalReceiver' with 'activemq-ra.rar' resource adapter
     And file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/ejb-jar.xml should contain queue/MY.CUSTOM.QUEUE.SIGNAL
     And file /opt/eap/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml should contain queue/MY.CUSTOM.QUEUE.SIGNAL

  Scenario: KIECLOUD-45 - Verify if the Audit queue is correctly configured with default configuration
    When container is started with env
      | variable                     | value  |
      | KIE_SERVER_JMS_ENABLE_AUDIT  | true   |
    Then container log should contain INFO Configuring Audit messaging queue
     And container log should contain Started message driven bean 'CompositeAsyncAuditLogReceiver' with 'activemq-ra.rar' resource adapter

  Scenario: KIECLOUD-45 - Verify if the Audit  queue is correctly configured with custom configuration
    When container is started with env
      | variable                     | value                        |
      | KIE_SERVER_JMS_ENABLE_AUDIT  | true                         |
      | KIE_SERVER_JMS_QUEUE_AUDIT   | queue/MY.CUSTOM.QUEUE.AUDIT  |
    Then container log should contain INFO Configuring Audit messaging queue
     And container log should contain Started message driven bean 'CompositeAsyncAuditLogReceiver' with 'activemq-ra.rar' resource adapter
     And file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/ejb-jar.xml should contain queue/MY.CUSTOM.QUEUE.AUDIT
     And file /opt/eap/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml should contain queue/MY.CUSTOM.QUEUE.AUDIT

  Scenario: Verify if the Audit and Signal queues are correctly configured with default configuration
    When container is started with env
      | variable                     | value  |
      | KIE_SERVER_JMS_ENABLE_AUDIT  | true   |
      | KIE_SERVER_JMS_ENABLE_SIGNAL | true   |
    Then container log should contain INFO Configuring Audit messaging queue
     And container log should contain Started message driven bean 'CompositeAsyncAuditLogReceiver' with 'activemq-ra.rar' resource adapter
     And container log should contain INFO Configuring Signal messaging queue
     And container log should contain Started message driven bean 'JMSSignalReceiver' with 'activemq-ra.rar' resource adapter

  Scenario: Verify if the Audit and Signal queues are correctly configured with custom configuration
    When container is started with env
      | variable                        | value                        |
      | KIE_SERVER_JMS_ENABLE_AUDIT     | true                         |
      | KIE_SERVER_JMS_AUDIT_TRANSACTED | false                        |
      | KIE_SERVER_JMS_QUEUE_AUDIT      | queue/MY.CUSTOM.QUEUE.AUDIT  |
      | KIE_SERVER_JMS_ENABLE_SIGNAL    | true                         |
      | KIE_SERVER_JMS_QUEUE_SIGNAL     | queue/MY.CUSTOM.QUEUE.SIGNAL |
    Then container log should contain INFO Configuring Audit messaging queue
     And container log should contain Started message driven bean 'CompositeAsyncAuditLogReceiver' with 'activemq-ra.rar' resource adapter
     And file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/ejb-jar.xml should contain queue/MY.CUSTOM.QUEUE.AUDIT
     And file /opt/eap/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml should contain queue/MY.CUSTOM.QUEUE.AUDIT
     And file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/classes/jbpm.audit.jms.properties should contain jbpm.audit.jms.queue.jndi=queue/MY.CUSTOM.QUEUE.AUDIT
     And file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/classes/jbpm.audit.jms.properties should contain jbpm.audit.jms.transacted=false
     And container log should contain INFO Configuring Signal messaging queue
     And container log should contain Started message driven bean 'JMSSignalReceiver' with 'activemq-ra.rar' resource adapter
     And file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/ejb-jar.xml should contain queue/MY.CUSTOM.QUEUE.SIGNAL
     And file /opt/eap/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml should contain queue/MY.CUSTOM.QUEUE.SIGNAL

  Scenario: Checks if the launch directory has the right permissions set
    When container is started with command bash
    Then run sh -c '[ $(ls -l /opt/eap/bin/launch/*.sh | wc -l) -gt 0 ] && echo "has script files"' in container and check its output for has script files
     And run sh -c 'exec=$(find -L /opt/eap/bin/launch -maxdepth 1 -type f -perm /u+x,g+x -name \*.sh | wc -l); nonexec=$(ls -l /opt/eap/bin/launch/*.sh | wc -l); [ $exec = $nonexec ] && echo "permissions ok"' in container and check its output for permissions ok

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

  Scenario: Verify if the EJB timer related setting are not set when AUTO_CONFIGURE_EJB_TIMER is false and no TIMER_SERVICE_DATA_STORE is given
    When container is started with env
      | variable                         | value |
      | AUTO_CONFIGURE_EJB_TIMER         | false |
    Then container log should not contain -Dorg.jbpm.ejb.timer.tx=true
     And container log should not contain -Dorg.jbpm.ejb.timer.local.cache=false

  Scenario: Verify if EJB timer related setting are set when  AUTO_CONFIGURE_EJB_TIMER is false and a TIMER_SERVICE_DATA_STORE is given
    When container is started with env
      | variable                         | value             |
      | AUTO_CONFIGURE_EJB_TIMER         | false             |
      | TIMER_SERVICE_DATA_STORE         | custom-data-store |
    Then container log should contain -Dorg.jbpm.ejb.timer.tx=true
    And container log should contain -Dorg.jbpm.ejb.timer.local.cache=false

  Scenario: Check KIE_SERVER_JBPM_CLUSTER flag enabled
    When container is started with env
      | variable                        | value                |
      | JGROUPS_PING_PROTOCOL           | kubernetes.KUBE_PING |
      | KIE_SERVER_JBPM_CLUSTER         | true                 |
    Then container log should contain KIE Server's cluster for Jbpm failover is enabled.
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 60000 on XPath //*[local-name()='cache-container'][@name='jbpm']/*[local-name()='transport']/@lock-timeout
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value BATCH on XPath //*[local-name()='cache-container'][@name='jbpm']/*[local-name()='replicated-cache'][@name='nodes']/*[local-name()='transaction']/@mode
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value BATCH on XPath //*[local-name()='cache-container'][@name='jbpm']/*[local-name()='replicated-cache'][@name='jobs']/*[local-name()='transaction']/@mode
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jbpm on XPath //*[local-name()='cache-container']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value nodes on XPath //*[local-name()='cache-container']/*[local-name()='replicated-cache'][@name='nodes']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jobs on XPath //*[local-name()='cache-container']/*[local-name()='replicated-cache'][@name='jobs']/@name
    And XML file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/jboss-deployment-structure.xml should contain value export on XPath  //*[local-name()='module'][@name='org.infinispan']/@services
    And XML file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/jboss-deployment-structure.xml should contain value org.infinispan on XPath  //*[local-name()='module'][@name='org.infinispan']/@name
    And XML file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/jboss-deployment-structure.xml should contain value org.jgroups on XPath  //*[local-name()='module'][@name='org.jgroups']/@name
    And run sh -c 'test -f /opt/eap/standalone/deployments/ROOT.war/WEB-INF/lib/kie-server-services-jbpm-cluster-*.jar && echo all good' in container and check its output for all good

  Scenario: Check jbpm cache transport lock timeout
    When container is started with env
      | variable                                       | value                |
      | JGROUPS_PING_PROTOCOL                          | kubernetes.KUBE_PING |
      | KIE_SERVER_JBPM_CLUSTER                        | true                 |
      | KIE_SERVER_JBPM_CLUSTER_TRANSPORT_LOCK_TIMEOUT | 120000               |
    Then container log should contain KIE Server's cluster for Jbpm failover is enabled.
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 120000 on XPath //*[local-name()='cache-container'][@name='jbpm']/*[local-name()='transport']/@lock-timeout

  Scenario: Check KIE_SERVER_JBPM_CLUSTER flag disabled
    When container is started with env
      | variable                        | value                |
      | JGROUPS_PING_PROTOCOL           | kubernetes.KUBE_PING |
      | KIE_SERVER_JBPM_CLUSTER         | false                |
    Then container log should contain KIE Server's cluster for Jbpm failover is disabled.
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <cache-container name="jbpm">

  Scenario: Check jbpm cache if KIE_SERVER_JBPM_CLUSTER isn't present
    When container is started with env
      | variable                        | value                |
      | JGROUPS_PING_PROTOCOL           | kubernetes.KUBE_PING |
    Then container log should contain KIE Server's cluster for Jbpm failover is disabled.
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <cache-container name="jbpm">

  Scenario: Check if the Kafka integration is disabled
    When container is started with env
      | variable                       | value    |
      | KIE_SERVER_KAFKA_EXT_ENABLED   | false    |
    Then container log should contain -Dorg.kie.kafka.server.ext.disabled=true

  Scenario: Check if the Kafka integration is enabled
    When container is started with env
      | variable                               | value                         |
      | KIE_SERVER_KAFKA_EXT_ENABLED           | true                          |
      | KIE_SERVER_KAFKA_EXT_BOOTSTRAP_SERVERS | localhost:9092                |
      | KIE_SERVER_KAFKA_EXT_CLIENT_ID         | app                           |
      | KIE_SERVER_KAFKA_EXT_GROUP_ID          | jbpm-consumer                 |
      | KIE_SERVER_KAFKA_EXT_ACKS              | 2                             |
      | KIE_SERVER_KAFKA_EXT_MAX_BLOCK_MS      | 2000                          |
      | KIE_SERVER_KAFKA_EXT_AUTOCREATE_TOPICS | true                          |
      | KIE_SERVER_KAFKA_EXT_TOPICS            | person=human,dog=animal,ant=  |
      | SCRIPT_DEBUG                           | true                          |
    Then container log should contain -Dorg.kie.kafka.server.ext.disabled=false
     And container log should contain -Dorg.kie.server.jbpm-kafka.ext.bootstrap.servers=localhost:9092
     And container log should contain -Dorg.kie.server.jbpm-kafka.ext.client.id=app
     And container log should contain -Dorg.kie.server.jbpm-kafka.ext.group.id=jbpm-consumer
     And container log should contain -Dorg.kie.server.jbpm-kafka.ext.acks=2
     And container log should contain -Dorg.kie.server.jbpm-kafka.ext.max.block.ms=2000
     And container log should contain -Dorg.kie.server.jbpm-kafka.ext.allow.auto.create.topics=true
     And container log should contain -Dorg.kie.server.jbpm-kafka.ext.topics.person=human
     And container log should contain -Dorg.kie.server.jbpm-kafka.ext.topics.dog=animal
     And container log should contain mapping not configured, msg or topic name is empty. Value set [ant=]

  Scenario: Check if the Kafka integration is enabled without bootstrapservers
    When container is started with env
      | variable                               | value                         |
      | KIE_SERVER_KAFKA_EXT_ENABLED           | true                          |
      | KIE_SERVER_KAFKA_EXT_CLIENT_ID         | app                           |
      | KIE_SERVER_KAFKA_EXT_GROUP_ID          | jbpm-consumer                 |
      | KIE_SERVER_KAFKA_EXT_ACKS              | 2                             |
      | KIE_SERVER_KAFKA_EXT_MAX_BLOCK_MS      | 2000                          |
      | KIE_SERVER_KAFKA_EXT_AUTOCREATE_TOPICS | true                          |
      | KIE_SERVER_KAFKA_EXT_TOPICS            | person=human,dog=animal,ant=  |
      | SCRIPT_DEBUG                           | true                          |
    Then container log should contain -Dorg.kie.kafka.server.ext.disabled=true
     And container log should contain Bootstrap servers not configured, kafka extension disabled

  Scenario: Check if the Kafka JBPM Emitter is enabled
    When container is started with env
      | variable                                                 | value                         |
      | KIE_SERVER_KAFKA_JBPM_EVENT_EMITTER_BOOTSTRAP_SERVERS    | localhost:9093                |
      | KIE_SERVER_KAFKA_JBPM_EVENT_EMITTER_ENABLED              | true                          |
      | KIE_SERVER_KAFKA_JBPM_EVENT_EMITTER_CLIENT_ID            | jbpmapp                       |
      | KIE_SERVER_KAFKA_JBPM_EVENT_EMITTER_ACKS                 | 3                             |
      | KIE_SERVER_KAFKA_JBPM_EVENT_EMITTER_MAX_BLOCK_MS         | 2100                          |
      | KIE_SERVER_KAFKA_JBPM_EVENT_EMITTER_DATE_FORMAT          | dd-MM-yyyy'T'HH:mm:ss.SSSZ    |
      | KIE_SERVER_KAFKA_JBPM_EVENT_EMITTER_PROCESSES_TOPIC_NAME | my-processes-topic            |
      | KIE_SERVER_KAFKA_JBPM_EVENT_EMITTER_TASKS_TOPIC_NAME     | my-tasks-topic                |
      | KIE_SERVER_KAFKA_JBPM_EVENT_EMITTER_CASES_TOPIC_NAME     | my-cases-topic                |
      | SCRIPT_DEBUG                                             | true                          |
    Then container log should contain -Dorg.kie.jbpm.event.emitters.kafka.bootstrap.servers=localhost:9093
     And container log should contain -Dorg.kie.jbpm.event.emitters.kafka.client.id=jbpmapp
     And container log should contain -Dorg.kie.jbpm.event.emitters.kafka.acks=3
     And container log should contain -Dorg.kie.jbpm.event.emitters.kafka.max.block.ms=2100
     And container log should contain -Dorg.kie.jbpm.event.emitters.kafka.date_format=dd-MM-yyyy'T'HH:mm:ss.SSSZ
     And container log should contain -Dorg.kie.jbpm.event.emitters.kafka.topic.processes=my-processes-topic
     And container log should contain -Dorg.kie.jbpm.event.emitters.kafka.topic.tasks=my-tasks-topic
     And container log should contain -Dorg.kie.jbpm.event.emitters.kafka.topic.cases=my-cases-topic
     And run sh -c 'test -f /opt/eap/standalone/deployments/ROOT.war/WEB-INF/lib/jbpm-event-emitters-kafka-*.jar && echo all good' in container and check its output for all good

  Scenario: Check if the Kafka JBPM Emitter is  without bootstrap
    When container is started with env
      | variable                                         | value                      |
      | KIE_SERVER_KAFKA_JBPM_EVENT_EMITTER_ENABLED      | true                       |
      | KIE_SERVER_KAFKA_JBPM_EVENT_EMITTER_CLIENT_ID    | jbpmapp                    |
      | KIE_SERVER_KAFKA_JBPM_EVENT_EMITTER_ACKS         | 3                          |
      | KIE_SERVER_KAFKA_JBPM_EVENT_EMITTER_MAX_BLOCK_MS | 2100                       |
      | KIE_SERVER_KAFKA_JBPM_EVENT_EMITTER_DATE_FORMAT  | dd-MM-yyyy'T'HH:mm:ss.SSSZ |
      | SCRIPT_DEBUG                                     | true                       |
    Then container log should contain -Dorg.kie.kafka.server.ext.disabled=true
     And container log should contain JBPM Emitter Bootstrap servers not configured

