@ibm-bamoe/bamoe-kieserver-rhel8
Feature: IBM BAMOE KIE Server configuration tests

  # https://issues.jboss.org/browse/CLOUD-180
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain ibm-bamoe/bamoe-kieserver-rhel8 image, version

  Scenario: Check for product and version environment variables
    When container is started with command bash
    Then run sh -c 'echo $JBOSS_PRODUCT' in container and check its output for ibm-bamoe-kieserver
     And run sh -c 'echo $IBM_BAMOE_KIESERVER_VERSION' in container and check its output for 8.0

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
    Then s2i build log should contain Attempting to verify kie server containers with 'java org.kie.server.services.impl.KieServerContainerVerifier  org.openshift.quickstarts:rhpam-kieserver-library:1.6.0-SNAPSHOT'
    And s2i build log should contain -Djavax.net.ssl.trustStore=truststore.ts -Djavax.net.ssl.trustStorePassword=123456
    And s2i build log should not contain And s2i build log should not contain java.lang.ClassNotFoundException: org.apache.maven.model.io.xpp3.MavenXpp3WriterEx

  Scenario: deploys the hellorules example, then checks if it's deployed. Additionally test if the JAVA_OPTS_APPEND is used in the container verifier step
    Given s2i build https://github.com/jboss-container-images/rhpam-7-openshift-image from quickstarts/hello-rules/hellorules using main
      | variable                        | value                                                                                        |
      | KIE_SERVER_CONTAINER_DEPLOYMENT | rhdm-kieserver-hellorules=org.openshift.quickstarts:rhpam-kieserver-decisions:1.6.0-SNAPSHOT |
      | JAVA_OPTS_APPEND                | -Djavax.net.ssl.trustStore=truststore.ts -Djavax.net.ssl.trustStorePassword=123456           |
      | SCRIPT_DEBUG                    | false                                                                                        |
    Then s2i build log should contain Attempting to verify kie server containers with 'java org.kie.server.services.impl.KieServerContainerVerifier  org.openshift.quickstarts:rhpam-kieserver-decisions:1.6.0-SNAPSHOT'
    And s2i build log should contain -Djavax.net.ssl.trustStore=truststore.ts -Djavax.net.ssl.trustStorePassword=123456
    And s2i build log should not contain java.lang.ClassNotFoundException: org.apache.maven.model.io.xpp3.MavenXpp3WriterEx

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

  Scenario: Checks if the EJB Timer was successfully configured with PostgreSQL with DB_SERVICE_PREFIX_MAPPING env
    When container is started with env
      | variable                                  | value                            |
      | DB_SERVICE_PREFIX_MAPPING                 | kie-app-postgresql=DB            |
      | DB_DRIVER                                 | postgresql                       |
      | DB_DATABASE                               | bpms                             |
      | DB_USERNAME                               | bpmUser                          |
      | DB_PASSWORD                               | bpmPass                          |
      | DB_JNDI                                   | java:jboss/datasources/ExampleDS |
      | DB_NONXA                                  | true                             |
      | KIE_APP_POSTGRESQL_SERVICE_HOST           | 10.1.1.1                         |
      | KIE_APP_POSTGRESQL_SERVICE_PORT           | 5432                             |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000                            |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS_EJBTimer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value kie_app_postgresql-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value kie_app_postgresql-DB on XPath //*[local-name()='datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS_EJBTimer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 5432 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PortNumber"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpms on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value kie_app_postgresql-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value kie_app_postgresql-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS_EJBTimer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value kie_app_postgresql-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='min-pool-size']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='max-pool-size']

  Scenario: Checks if the EJB Timer was successfully configured with PostgreSQL with DATASOURCES env
    When container is started with env
      | variable                                  | value                                                                             |
      | DATASOURCES                               | TEST                                                                              |
      | TEST_DATABASE                             | bpms                                                                              |
      | TEST_USERNAME                             | bpmUser                                                                           |
      | TEST_PASSWORD                             | bpmPass                                                                           |
      | TEST_DRIVER                               | postgresql                                                                        |
      | TEST_SERVICE_HOST                         | 10.1.1.1                                                                          |
      | TEST_SERVICE_PORT                         | 5432                                                                              |
      | TEST_NONXA                                | true                                                                              |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000                                                                             |
      | TEST_CONNECTION_CHECKER                   | org.jboss.jca.adapters.jdbc.extensions.postgres.PostgreSQLValidConnectionChecker  |
      | TEST_EXCEPTION_SORTER                     | org.jboss.jca.adapters.jdbc.extensions.postgres.PostgreSQLExceptionSorter         |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 5432 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PortNumber"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpms on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='min-pool-size']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='max-pool-size']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='validation']/*[local-name()='validate-on-match']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='validation']/*[local-name()='background-validation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.postgres.PostgreSQLValidConnectionChecker on XPath //*[local-name()='validation']/*[local-name()='valid-connection-checker']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.postgres.PostgreSQLExceptionSorter on XPath //*[local-name()='validation']/*[local-name()='exception-sorter']/@class-name
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain value jdbc:postgresql://:/
     And container log should not contain WARN Missing configuration for XA datasource EJB_TIMER


  Scenario: Checks if the EJB Timer was successfully configured with PostgreSQL with DATASOURCES env with custom driver name
    When container is started with env
      | variable                                  | value        |
      | DATASOURCES                               | TEST         |
      | TEST_DATABASE                             | bpms         |
      | TEST_USERNAME                             | bpmUser      |
      | TEST_PASSWORD                             | bpmPass      |
      | TEST_DRIVER                               | postgresql96 |
      | TEST_SERVICE_HOST                         | 10.1.1.1     |
      | TEST_SERVICE_PORT                         | 5432         |
      | TEST_NONXA                                | true         |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000        |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql96 on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 5432 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PortNumber"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpms on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql96 on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='min-pool-size']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='max-pool-size']
     And container log should not contain WARN Missing configuration for XA datasource EJB_TIMER

  Scenario: Checks if the EJB Timer was successfully configured with XA PostgreSQL with DATASOURCES env
    When container is started with env
      | variable                                  | value        |
      | DATASOURCES                               | TEST         |
      | TEST_DATABASE                             | bpms         |
      | TEST_USERNAME                             | bpmUser      |
      | TEST_PASSWORD                             | bpmPass      |
      | TEST_DRIVER                               | postgresql96 |
      | TEST_XA_CONNECTION_PROPERTY_ServerName    | 10.1.1.1     |
      | TEST_XA_CONNECTION_PROPERTY_DatabaseName  | bpms         |
      | TEST_XA_CONNECTION_PROPERTY_PortNumber    | 5432         |
      | TEST_NONXA                                | false        |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000        |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql96 on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 5432 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PortNumber"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpms on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql96 on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='min-pool-size']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='max-pool-size']
     And container log should not contain WARN Missing configuration for XA datasource EJB_TIMER

  Scenario: Checks if the EJB Timer was successfully configured with PostgreSQL with DATASOURCES env using setting URL
    When container is started with env
      | variable                                  | value                                |
      | DATASOURCES                               | TEST                                 |
      | TEST_DATABASE                             | bpms                                 |
      | TEST_USERNAME                             | bpmUser                              |
      | TEST_PASSWORD                             | bpmPass                              |
      | TEST_DRIVER                               | postgresql                           |
      | TEST_URL                                  | jdbc:postgresql://10.1.1.1:3306/bpms |
      | TEST_NONXA                                | true                                 |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000                                |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:postgresql://10.1.1.1:3306/bpms on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Url"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:postgresql://10.1.1.1:3306/bpms on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='min-pool-size']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='max-pool-size']

  Scenario: Checks if the EJB Timer was successfully configured with PostgreSQL with DATASOURCES env using setting URL with additional parameters
    When container is started with env
      | variable                                  | value                                                                 |
      | DATASOURCES                               | TEST                                                                  |
      | TEST_DATABASE                             | bpms                                                                  |
      | TEST_USERNAME                             | bpmUser                                                               |
      | TEST_PASSWORD                             | bpmPass                                                               |
      | TEST_DRIVER                               | postgresql                                                            |
      | TEST_URL                                  | jdbc:postgresql://10.1.1.1:3306/bpms?ssl=true&amp;sslmode=allow       |
      | TEST_NONXA                                | true                                                                  |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000                                                                 |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:postgresql://10.1.1.1:3306/bpms?ssl=true&sslmode=allow on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Url"]
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:postgresql://10.1.1.1:3306/bpms?ssl=true&sslmode=allow on XPath //*[local-name()='datasource'][@pool-name='test-TEST']/*[local-name()='connection-url']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql on XPath //*[local-name()='database-data-store']/@database
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval

  Scenario: Checks if the EJB Timer was successfully configured with MySQL with DB_SERVICE_PREFIX_MAPPING env
    When container is started with env
      | variable                   | value                            |
      | DB_SERVICE_PREFIX_MAPPING  | kie-app-mysql=DB                 |
      | DB_DRIVER                  | mysql                            |
      | DB_DATABASE                | bpms                             |
      | DB_USERNAME                | bpmUser                          |
      | DB_PASSWORD                | bpmPass                          |
      | DB_JNDI                    | java:jboss/datasources/ExampleDS |
      | DB_NONXA                   | true                             |
      | KIE_APP_MYSQL_SERVICE_HOST | 10.1.1.1                         |
      | KIE_APP_MYSQL_SERVICE_PORT | 3306                             |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value kie_app_mysql-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value kie_app_mysql-DB on XPath //*[local-name()='datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS on XPath //*[local-name()='datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS_EJBTimer on XPath //*[local-name()='xa-datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpms on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 3306 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Port"]
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value kie_app_mysql-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value kie_app_mysql-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS_EJBTimer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='database-data-store']/@database
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value kie_app_mysql-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='min-pool-size']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='max-pool-size']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/bpms?pinGlobalTxToPhysicalConnection=true&enabledTLSProtocols=TLSv1.2 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="PinGlobalTxToPhysicalConnection">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="EnabledTLSProtocols">

  Scenario: Checks if the EJB Timer was successfully configured with MySQL XA with DATASOURCES env
    When container is started with env
      | variable                                  | value                                                                     |
      | DATASOURCES                               | TEST                                                                      |
      | TEST_USERNAME                             | bpmUser                                                                   |
      | TEST_PASSWORD                             | bpmPass                                                                   |
      | TEST_DRIVER                               | mysql                                                                     |
      | TEST_BACKGROUND_VALIDATION                | false                                                                     |
      | TEST_CONNECTION_CHECKER                   | org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLValidConnectionChecker  |
      | TEST_EXCEPTION_SORTER                     | org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLExceptionSorter         |
      | TEST_XA_CONNECTION_PROPERTY_ServerName    | 10.1.1.1                                                                  |
      | TEST_XA_CONNECTION_PROPERTY_DatabaseName  | bpms                                                                      |
      | TEST_XA_CONNECTION_PROPERTY_Port          | 3306                                                                      |
      | TEST_NONXA                                | false                                                                     |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000                                                                     |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 3306 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Port"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpms on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='min-pool-size']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='max-pool-size']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='validation']/*[local-name()='validate-on-match']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='validation']/*[local-name()='background-validation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLValidConnectionChecker on XPath //*[local-name()='validation']/*[local-name()='valid-connection-checker']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLExceptionSorter on XPath //*[local-name()='validation']/*[local-name()='exception-sorter']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/bpms?pinGlobalTxToPhysicalConnection=true&enabledTLSProtocols=TLSv1.2 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="PinGlobalTxToPhysicalConnection">
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="EnabledTLSProtocols">
     And container log should not contain WARN Missing configuration for XA datasource EJB_TIMER

  Scenario: Checks if the EJB Timer was successfully configured with MySQL with DATASOURCES env
    When container is started with env
      | variable                                  | value                                                                     |
      | DATASOURCES                               | TEST                                                                      |
      | TEST_DATABASE                             | bpms                                                                      |
      | TEST_USERNAME                             | bpmUser                                                                   |
      | TEST_PASSWORD                             | bpmPass                                                                   |
      | TEST_DRIVER                               | mysql                                                                     |
      | TEST_SERVICE_HOST                         | 10.1.1.1                                                                  |
      | TEST_SERVICE_PORT                         | 3306                                                                      |
      | TEST_NONXA                                | true                                                                      |
      | TEST_BACKGROUND_VALIDATION                | false                                                                     |
      | TEST_CONNECTION_CHECKER                   | org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLValidConnectionChecker  |
      | TEST_EXCEPTION_SORTER                     | org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLExceptionSorter         |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000                                                                     |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 3306 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Port"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpms on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='min-pool-size']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='max-pool-size']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='validation']/*[local-name()='validate-on-match']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='validation']/*[local-name()='background-validation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLValidConnectionChecker on XPath //*[local-name()='validation']/*[local-name()='valid-connection-checker']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLExceptionSorter on XPath //*[local-name()='validation']/*[local-name()='exception-sorter']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/bpms?pinGlobalTxToPhysicalConnection=true&enabledTLSProtocols=TLSv1.2 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="PinGlobalTxToPhysicalConnection">
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="EnabledTLSProtocols">
     And container log should not contain WARN Missing configuration for XA datasource EJB_TIMER

  Scenario: Checks if the EJB Timer was successfully configured with MySQL with DATASOURCES env custom driver
    When container is started with env
      | variable                                  | value      |
      | DATASOURCES                               | TEST       |
      | TEST_DATABASE                             | bpms       |
      | TEST_USERNAME                             | bpmUser    |
      | TEST_PASSWORD                             | bpmPass    |
      | TEST_DRIVER                               | mysql57    |
      | TEST_SERVICE_HOST                         | 10.1.1.1   |
      | TEST_SERVICE_PORT                         | 3306       |
      | TEST_NONXA                                | true       |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000      |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql57 on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 3306 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Port"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpms on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/bpms?enabledTLSProtocols=TLSv1.2 on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql57 on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='min-pool-size']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='max-pool-size']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/bpms?pinGlobalTxToPhysicalConnection=true&enabledTLSProtocols=TLSv1.2 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="PinGlobalTxToPhysicalConnection">
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="EnabledTLSProtocols">
     And container log should not contain WARN Missing configuration for XA datasource EJB_TIMER

  Scenario: Checks if the EJB Timer was successfully configured with MySQL with DATASOURCES env using custom driver name and URL
    When container is started with env
      | variable                                  | value                           |
      | DATASOURCES                               | TEST                            |
      | TEST_DATABASE                             | bpms                            |
      | TEST_USERNAME                             | bpmUser                         |
      | TEST_PASSWORD                             | bpmPass                         |
      | TEST_DRIVER                               | mysql57                         |
      | TEST_URL                                  | jdbc:mysql://10.1.1.1:3306/bpms |
      | TEST_NONXA                                | true                            |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000                           |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql57 on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/bpms?pinGlobalTxToPhysicalConnection=true&enabledTLSProtocols=TLSv1.2 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/bpms?enabledTLSProtocols=TLSv1.2 on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql57 on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='min-pool-size']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='max-pool-size']
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="PinGlobalTxToPhysicalConnection">
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="EnabledTLSProtocols">

  Scenario: Checks if the EJB Timer was successfully configured with MySQL with DATASOURCES env using custom driver name and URL with parameter
    When container is started with env
      | variable                                  | value                                        |
      | DATASOURCES                               | TEST                                         |
      | TEST_DATABASE                             | bpms                                         |
      | TEST_USERNAME                             | bpmUser                                      |
      | TEST_PASSWORD                             | bpmPass                                      |
      | TEST_DRIVER                               | mysql57                                      |
      | TEST_URL                                  | jdbc:mysql://10.1.1.1:3306/bpms?useSSL=false |
      | TEST_NONXA                                | true                                         |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000                                        |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql57 on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/bpms?useSSL=false&pinGlobalTxToPhysicalConnection=true&enabledTLSProtocols=TLSv1.2 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/bpms?useSSL=false&enabledTLSProtocols=TLSv1.2 on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql57 on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='min-pool-size']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='max-pool-size']
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="PinGlobalTxToPhysicalConnection">
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="EnabledTLSProtocols">

  Scenario: Checks if the EJB Timer was successfully configured with MySQL with DATASOURCES env with URL
    When container is started with env
      | variable                                  | value                           |
      | DATASOURCES                               | TEST                            |
      | TEST_DATABASE                             | bpms                            |
      | TEST_USERNAME                             | bpmUser                         |
      | TEST_PASSWORD                             | bpmPass                         |
      | TEST_DRIVER                               | mysql                           |
      | TEST_URL                                  | jdbc:mysql://10.1.1.1:3306/bpms |
      | TEST_XA_CONNECTION_PROPERTY_URL           | jdbc:mysql://10.1.1.1:3306/bpms |
      | TEST_NONXA                                | true                            |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000                           |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/bpms?pinGlobalTxToPhysicalConnection=true&enabledTLSProtocols=TLSv1.2 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/bpms?enabledTLSProtocols=TLSv1.2 on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval

  Scenario: Checks if the EJB Timer was successfully configured with MySQL with DATASOURCES env with custom jndi
    When container is started with env
      | variable                                  | value                         |
      | DATASOURCES                               | TEST                          |
      | TEST_DATABASE                             | bpms                          |
      | TEST_USERNAME                             | bpmUser                       |
      | TEST_PASSWORD                             | bpmPass                       |
      | TEST_DRIVER                               | mysql                         |
      | TEST_SERVICE_HOST                         | 10.1.1.1                      |
      | TEST_SERVICE_PORT                         | 3306                          |
      | TEST_NONXA                                | true                          |
      | TEST_JNDI                                 | java:jboss/datasources/myJndi |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000                         |
   Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/myJndi on XPath //*[local-name()='datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='datasource']/@enabled
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='datasource']/@use-java-context
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/myJndi_EJBTimer on XPath //*[local-name()='xa-datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 3306 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Port"]
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpms on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/myJndi_EJBTimer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='database-data-store']/@database
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/bpms?pinGlobalTxToPhysicalConnection=true&enabledTLSProtocols=TLSv1.2 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="PinGlobalTxToPhysicalConnection">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="EnabledTLSProtocols">

  Scenario: Checks if the EJB Timer was successfully configured with MySQL with DB_SERVICE_PREFIX_MAPPING env
    When container is started with env
      | variable                     | value                            |
      | DB_SERVICE_PREFIX_MAPPING    | kie-app-mariadb=DB               |
      | DB_DRIVER                    | mariadb                          |
      | DB_DATABASE                  | bpms                             |
      | DB_USERNAME                  | bpmUser                          |
      | DB_PASSWORD                  | bpmPass                          |
      | DB_JNDI                      | java:jboss/datasources/ExampleDS |
      | DB_NONXA                     | true                             |
      | KIE_APP_MARIADB_SERVICE_HOST | 10.1.1.1                         |
      | KIE_APP_MARIADB_SERVICE_PORT | 3306                             |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value kie_app_mariadb-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value kie_app_mariadb-DB on XPath //*[local-name()='datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS on XPath //*[local-name()='datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mariadb on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS_EJBTimer on XPath //*[local-name()='xa-datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpms on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 3306 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Port"]
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value kie_app_mariadb-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value kie_app_mariadb-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS_EJBTimer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mariadb on XPath //*[local-name()='database-data-store']/@database
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value kie_app_mariadb-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='min-pool-size']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='max-pool-size']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mariadb://10.1.1.1:3306/bpms?pinGlobalTxToPhysicalConnection=true&enabledSslProtocolSuites=TLSv1.2 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Url"]
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="PinGlobalTxToPhysicalConnection">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="EnabledSslProtocolSuites">

  Scenario: Checks if the EJB Timer was successfully configured with MariaDB with DATASOURCES env custom driver
    When container is started with env
      | variable                                  | value      |
      | DATASOURCES                               | TEST       |
      | TEST_DATABASE                             | bpms       |
      | TEST_USERNAME                             | bpmUser    |
      | TEST_PASSWORD                             | bpmPass    |
      | TEST_DRIVER                               | mariadbTest|
      | TEST_SERVICE_HOST                         | 10.1.1.1   |
      | TEST_SERVICE_PORT                         | 3306       |
      | TEST_NONXA                                | true       |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000      |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mariadbTest on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 3306 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Port"]
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpms on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mariadb://10.1.1.1:3306/bpms?enabledSslProtocolSuites=TLSv1.2 on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mariadbTest on XPath //*[local-name()='database-data-store']/@database
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='min-pool-size']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='max-pool-size']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mariadb://10.1.1.1:3306/bpms?pinGlobalTxToPhysicalConnection=true&enabledSslProtocolSuites=TLSv1.2 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Url"]
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="PinGlobalTxToPhysicalConnection">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="EnabledSslProtocolSuites">
    And container log should not contain WARN Missing configuration for XA datasource EJB_TIMER

  Scenario: Checks if the EJB Timer was successfully configured with MariaDB with DATASOURCES env using custom driver name and URL
    When container is started with env
      | variable                                  | value                             |
      | DATASOURCES                               | TEST                              |
      | TEST_DATABASE                             | bpms                              |
      | TEST_USERNAME                             | bpmUser                           |
      | TEST_PASSWORD                             | bpmPass                           |
      | TEST_DRIVER                               | mariadb                           |
      | TEST_URL                                  | jdbc:mariadb://10.1.1.1:3306/bpms |
      | TEST_NONXA                                | true                              |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000                             |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mariadb on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mariadb://10.1.1.1:3306/bpms?pinGlobalTxToPhysicalConnection=true&enabledSslProtocolSuites=TLSv1.2 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Url"]
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mariadb://10.1.1.1:3306/bpms?enabledSslProtocolSuites=TLSv1.2 on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mariadb on XPath //*[local-name()='database-data-store']/@database
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='min-pool-size']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='max-pool-size']

  Scenario: Checks if the EJB Timer was successfully configured with MariaDB with DATASOURCES env using custom driver name and URL with prameter
    When container is started with env
      | variable                                  | value                                          |
      | DATASOURCES                               | TEST                                           |
      | TEST_DATABASE                             | bpms                                           |
      | TEST_USERNAME                             | bpmUser                                        |
      | TEST_PASSWORD                             | bpmPass                                        |
      | TEST_DRIVER                               | mariadb                                        |
      | TEST_URL                                  | jdbc:mariadb://10.1.1.1:3306/bpms?useSSL=false |
      | TEST_NONXA                                | true                                           |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000                                          |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mariadb on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mariadb://10.1.1.1:3306/bpms?useSSL=false&pinGlobalTxToPhysicalConnection=true&enabledSslProtocolSuites=TLSv1.2 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Url"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mariadb://10.1.1.1:3306/bpms?useSSL=false&enabledSslProtocolSuites=TLSv1.2 on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mariadb on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='min-pool-size']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='max-pool-size']

  Scenario: Checks if the EJB Timer was successfully configured for an external Oracle datasource with DATASOURCES env using XA URL property
    When container is started with env
      | variable                                  | value                                                                       |
      | DATASOURCES                               | TEST                                                                        |
      | TEST_USERNAME                             | bpmUser                                                                     |
      | TEST_PASSWORD                             | bpmPass                                                                     |
      | TEST_DRIVER                               | oracle                                                                      |
      | TEST_XA_CONNECTION_PROPERTY_URL           | jdbc:oracle:thin:@test.com:1521:bpms                                        |
      | TEST_URL                                  | jdbc:oracle:thin:@test.com:1521:bpms                                        |
      | TEST_NONXA                                | false                                                                       |
      | TEST_CONNECTION_CHECKER                   | org.jboss.jca.adapters.jdbc.extensions.oracle.OracleValidConnectionChecker  |
      | TEST_EXCEPTION_SORTER                     | org.jboss.jca.adapters.jdbc.extensions.oracle.OracleExceptionSorter         |
      | TEST_BACKGROUND_VALIDATION                | true                                                                        |
      | TEST_BACKGROUND_VALIDATION_MILLIS         | 6000                                                                        |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000                                                                       |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value oracle on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:oracle:thin:@test.com:1521:bpms on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value oracle on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='validate-on-match']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='background-validation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 6000 on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='background-validation-millis']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.oracle.OracleValidConnectionChecker on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='valid-connection-checker']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.oracle.OracleExceptionSorter on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='exception-sorter']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval

  Scenario: Checks if the EJB Timer is correctly configured with with Oracle HA jdbc URL
    When container is started with env
      | variable                                  | value                                                                       |
      | DATASOURCES                               | TEST                                                                        |
      | TEST_USERNAME                             | bpmUser                                                                     |
      | TEST_PASSWORD                             | bpmPass                                                                     |
      | TEST_DRIVER                               | oracle                                                                      |
      | TEST_URL                                  | jdbc:oracle:thin:@(DESCRIPTION=     (LOAD_BALANCE=on)   (ADDRESS_LIST= (ADDRESS=(PROTOCOL=TCP)(HOST=host1) (PORT=1521)) (ADDRESS=(PROTOCOL=TCP)(HOST=host2)(PORT=1521))) (CONNECT_DATA=(SERVICE_NAME=service_name)))  |
      | TEST_NONXA                                | true                                                                       |
      | TEST_CONNECTION_CHECKER                   | org.jboss.jca.adapters.jdbc.extensions.oracle.OracleValidConnectionChecker  |
      | TEST_EXCEPTION_SORTER                     | org.jboss.jca.adapters.jdbc.extensions.oracle.OracleExceptionSorter         |
      | TEST_BACKGROUND_VALIDATION                | true                                                                        |
      | TEST_BACKGROUND_VALIDATION_MILLIS         | 6000                                                                        |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000                                                                       |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value oracle on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:oracle:thin:@(DESCRIPTION=(LOAD_BALANCE=on)(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=host1)(PORT=1521))(ADDRESS=(PROTOCOL=TCP)(HOST=host2)(PORT=1521)))(CONNECT_DATA=(SERVICE_NAME=service_name))) on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:oracle:thin:@(DESCRIPTION=(LOAD_BALANCE=on)(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=host1)(PORT=1521))(ADDRESS=(PROTOCOL=TCP)(HOST=host2)(PORT=1521)))(CONNECT_DATA=(SERVICE_NAME=service_name))) on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value oracle on XPath //*[local-name()='database-data-store']/@database
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='validate-on-match']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='background-validation']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 6000 on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='background-validation-millis']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.oracle.OracleValidConnectionChecker on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='valid-connection-checker']/@class-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.oracle.OracleExceptionSorter on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='exception-sorter']/@class-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval


  Scenario: Checks if the EJB Timer was successfully configured for an external DB2 datasource with Type 4 (default type) and env using XA connection properties XA
    When container is started with env
      | variable                                  | value                           |
      | DATASOURCES                               | TEST                            |
      | TEST_USERNAME                             | bpmUser                         |
      | TEST_PASSWORD                             | bpmPass                         |
      | TEST_DRIVER                               | db2                             |
      | TEST_XA_CONNECTION_PROPERTY_ServerName    | 127.0.0.1                       |
      | TEST_XA_CONNECTION_PROPERTY_DatabaseName  | bpms                            |
      | TEST_XA_CONNECTION_PROPERTY_PortNumber    | 50000                           |
      | TEST_NONXA                                | false                           |
      | TEST_DRIVER_TYPE                          | 4                               |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 127.0.0.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpms on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 50000 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PortNumber"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 4 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DriverType"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='xa-datasource']/@jndi-name

  Scenario: Checks if the EJB Timer was successfully configured for an external DB2 datasource with Type as default value and env using NONXA connection properties
    When container is started with env
      | variable                                  | value                             |
      | DATASOURCES                               | TEST                              |
      | TEST_USERNAME                             | bpmUser                           |
      | TEST_PASSWORD                             | bpmPass                           |
      | TEST_DRIVER                               | db2                               |
      | TEST_URL                                  | jdbc:db2://localhost:50000/dbtest |
      | TEST_NONXA                                | true                              |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value localhost on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value dbtest on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 50000 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PortNumber"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 4 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DriverType"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:db2://localhost:50000/dbtest on XPath //*[local-name()='datasource']/*[local-name()='connection-url']

  Scenario: Checks if the EJB Timer was successfully configured for an external DB2 datasource with Type as default value and env using XA connection properties
    When container is started with env
      | variable                                  | value                             |
      | DATASOURCES                               | TEST                              |
      | TEST_USERNAME                             | bpmUser                           |
      | TEST_PASSWORD                             | bpmPass                           |
      | TEST_DRIVER                               | db2                               |
      | TEST_URL                                  | jdbc:db2://localhost:50000/dbtest |
      | TEST_NONXA                                | true                              |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value localhost on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value dbtest on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 50000 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PortNumber"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 4 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DriverType"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:db2://localhost:50000/dbtest on XPath //*[local-name()='datasource']/*[local-name()='connection-url']

  Scenario: Checks if the EJB Timer was successfully configured for an external DB2 datasource with Type 2 and env using XA connection properties
    When container is started with env
      | variable                                  | value                           |
      | DATASOURCES                               | TEST                            |
      | TEST_USERNAME                             | bpmUser                         |
      | TEST_PASSWORD                             | bpmPass                         |
      | TEST_DRIVER                               | db2                             |
      | TEST_URL                                  | jdbc:db2://localhost:50000/test |
      | TEST_NONXA                                | true                            |
      | TEST_DRIVER_TYPE                          | 2                               |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value localhost on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 50000 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PortNumber"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 2 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DriverType"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='database-data-store']/@database

  Scenario: Checks if the EJB Timer was successfully configured with DB2 with SERVICE_HOST and PORT envs
    When container is started with env
      | variable                                  | value        |
      | DATASOURCES                               | TEST         |
      | TEST_DATABASE                             | bpms         |
      | TEST_USERNAME                             | bpmUser      |
      | TEST_PASSWORD                             | bpmPass      |
      | TEST_DRIVER                               | db2          |
      | TEST_SERVICE_HOST                         | 10.1.1.1     |
      | TEST_SERVICE_PORT                         | 50000        |
      | TEST_NONXA                                | true         |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000        |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 50000 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PortNumber"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpms on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:db2://10.1.1.1:50000/bpms on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval

  Scenario: Checks if the EJB Timer was successfully configured with DB2 with SERVICE_HOST and PORT envs with IS_SAME_OVERRIDE and NO_TX_SEPARATE_TOOLS envs set
    When container is started with env
      | variable                                  | value        |
      | DATASOURCES                               | TEST         |
      | TEST_DATABASE                             | bpms         |
      | TEST_USERNAME                             | bpmUser      |
      | TEST_PASSWORD                             | bpmPass      |
      | TEST_DRIVER                               | db2          |
      | TEST_SERVICE_HOST                         | 10.1.1.1     |
      | TEST_SERVICE_PORT                         | 50000        |
      | TEST_NONXA                                | true         |
      | TEST_IS_SAME_RM_OVERRIDE                  | true         |
      | TEST_NO_TX_SEPARATE_POOLS                 | true         |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000        |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:db2://10.1.1.1:50000/bpms on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-pool']/*[local-name()='is-same-rm-override']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-pool']/*[local-name()='no-tx-separate-pools']

  Scenario: Test external xa datasource extension
    When container is started with env
      | variable                          | value                                      |
      | DATASOURCES                       | TEST                                       |
      | TEST_JNDI                         | java:/jboss/datasources/testds             |
      | TEST_DRIVER                       | oracle                                     |
      | TEST_USERNAME                     | tombrady                                   |
      | TEST_PASSWORD                     | password                                   |
      | TEST_XA_CONNECTION_PROPERTY_URL   | jdbc:oracle:thin:@samplehost:1521:oracledb |
      | TEST_NONXA                        | false                                      |
      | TEST_JTA                          | true                                       |
      | TEST_IS_SAME_RM_OVERRIDE          | false                                      |
      | TEST_NO_TX_SEPARATE_POOLS         | true                                       |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testds on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:oracle:thin:@samplehost:1521:oracledb on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value oracle on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value tombrady on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value password on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-pool']/*[local-name()='is-same-rm-override']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-pool']/*[local-name()='no-tx-separate-pools']

  Scenario: Test external datasource extension, should not contain is-same-override and shouldnot contain no-tx-separate-pools
    When container is started with env
      | variable                          | value                                      |
      | DATASOURCES                       | TEST                                       |
      | TEST_JNDI                         | java:/jboss/datasources/testds             |
      | TEST_DRIVER                       | oracle                                     |
      | TEST_USERNAME                     | tombrady                                   |
      | TEST_PASSWORD                     | password                                   |
      | TEST_CONNECTION_PROPERTY_URL      | jdbc:oracle:thin:@samplehost:1521:oracledb |
      | TEST_JTA                          | true                                       |
      | TEST_IS_SAME_RM_OVERRIDE          | false                                      |
      | TEST_NO_TX_SEPARATE_POOLS         | true                                       |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testds on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value oracle on XPath //*[local-name()='datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value tombrady on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value password on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='datasource']/*[local-name()='pool']/*[local-name()='is-same-rm-override']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='datasource']/*[local-name()='pool']/*[local-name()='no-tx-separate-pools']

  Scenario: Verify if the DB Schema and persistence dialect is correctly set.
    When container is started with env
      | variable                        | value                            |
      | KIE_SERVER_PERSISTENCE_SCHEMA   | schema.a                         |
      | KIE_SERVER_PERSISTENCE_DIALECT  | org.hibernate.dialect.DB2Dialect |
      | KIE_SERVER_PERSISTENCE_DS       | java:jboss/datasources/yes       |
      | KIE_SERVER_PERSISTENCE_TM       | tmTest                           |
    Then container log should contain -Dorg.kie.server.persistence.schema=schema.a
     And container log should contain -Dorg.kie.server.persistence.dialect=org.hibernate.dialect.DB2Dialect
     And container log should contain -Dorg.kie.server.persistence.ds=java:jboss/datasources/yes
     And container log should contain -Dorg.kie.server.persistence.tm=tmTest

  Scenario: Checks if the EJB Timer was successfully configured with MariaDB with DATASOURCES env
    When container is started with env
      | variable                                  | value        |
      | DATASOURCES                               | TEST         |
      | TEST_DATABASE                             | bpms         |
      | TEST_USERNAME                             | bpmUser      |
      | TEST_PASSWORD                             | bpmPass      |
      | TEST_DRIVER                               | mariadb      |
      | TEST_SERVICE_HOST                         | 10.1.1.1     |
      | TEST_SERVICE_PORT                         | 3306         |
      | TEST_NONXA                                | true         |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000        |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mariadb on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 3306 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Port"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpms on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mariadb://10.1.1.1:3306/bpms?enabledSslProtocolSuites=TLSv1.2 on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mariadb on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='min-pool-size']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='max-pool-size']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mariadb://10.1.1.1:3306/bpms?pinGlobalTxToPhysicalConnection=true&enabledSslProtocolSuites=TLSv1.2 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Url"]
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="PinGlobalTxToPhysicalConnection">

  Scenario: Checks if the EJB Timer was successfully configured with MariaDB with DATASOURCES env XA
    When container is started with env
      | variable                                  | value        |
      | DATASOURCES                               | TEST         |
      | TEST_DATABASE                             | bpms         |
      | TEST_USERNAME                             | bpmUser      |
      | TEST_PASSWORD                             | bpmPass      |
      | TEST_DRIVER                               | mariadb      |
      | TEST_XA_CONNECTION_PROPERTY_ServerName    | 127.0.0.1    |
      | TEST_XA_CONNECTION_PROPERTY_DatabaseName  | bpms         |
      | TEST_XA_CONNECTION_PROPERTY_Port          | 3306         |
      | TEST_NONXA                                | false        |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000        |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mariadb on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 127.0.0.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 3306 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Port"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpms on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mariadb on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='min-pool-size']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='max-pool-size']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mariadb://127.0.0.1:3306/bpms?pinGlobalTxToPhysicalConnection=true&enabledSslProtocolSuites=TLSv1.2 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Url"]
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="PinGlobalTxToPhysicalConnection">

  Scenario: Checks if the EJB Timer and common datasource were created
    When container is started with env
      | variable                         | value                                           |
      | DATASOURCES                      | RHPAM                                           |
      | RHPAM_DATABASE                   | rhpam7                                          |
      | RHPAM_JNDI                       | java:jboss/datasources/rhpam                    |
      | RHPAM_JTA                        | true                                            |
      | RHPAM_DRIVER                     | h2                                              |
      | RHPAM_USERNAME                   | sa                                              |
      | RHPAM_PASSWORD                   | 123456                                          |
      | RHPAM_XA_CONNECTION_PROPERTY_URL | jdbc:h2:/opt/kie/data/h2/rhpam;AUTO_SERVER=TRUE |
      | RHPAM_SERVICE_HOST               | dummy                                           |
      | RHPAM_SERVICE_PORT               | 12345                                           |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/rhpam on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value rhpam-RHPAM on XPath //*[local-name()='datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value h2 on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:h2:/opt/kie/data/h2/rhpam;AUTO_SERVER=TRUE on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/rhpam_EJBTimer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:h2:/opt/kie/data/h2/rhpam;AUTO_SERVER=TRUE on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value sa on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 123456 on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/rhpam_EJBTimer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value h2 on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value -1 on XPath //*[local-name()='database-data-store']/@refresh-interval
     And container log should contain -Dorg.jbpm.ejb.timer.tx=true
     And container log should contain -Dorg.jbpm.ejb.timer.local.cache=false

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

  Scenario: RHPAM-3211 Openshift properties related to passwords in EJB_TIMER cannot use literal $n
    When container is started with env
      | variable         | value       |
      | RHPAM_USERNAME   | rhpam$0     |
      | RHPAM_PASSWORD   | kieserver$0 |
      | DATASOURCES      | RHPAM       |
      | RHPAM_DATABASE   | rhpam7      |
      | RHPAM_DRIVER     | postgresql  |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <password>kieserver$0</password>
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <user-name>rhpam$0</user-name>

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

