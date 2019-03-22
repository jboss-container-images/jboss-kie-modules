@rhpam-7/rhpam74-kieserver-openshift
Feature: RHPAM KIE Server configuration tests

  # https://issues.jboss.org/browse/CLOUD-180
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain rhpam-7/rhpam74-kieserver-openshift image, version

  Scenario: Check for product and version environment variables
    When container is ready
    Then run sh -c 'echo $JBOSS_PRODUCT' in container and check its output for rhpam-kieserver
     And run sh -c 'echo $RHPAM_KIESERVER_VERSION' in container and check its output for 7.4

  Scenario: Check custom war file was successfully deployed via CUSTOM_INSTALL_DIRECTORIES
    Given s2i build https://github.com/jboss-openshift/openshift-examples.git from custom-install-directories
      | variable   | value                    |
      | CUSTOM_INSTALL_DIRECTORIES | custom   |
    Then file /opt/eap/standalone/deployments/node-info.war should exist

  # KIECLOUD-11: temporarily ignore since Jenkins CI builds currently fail with this test, even though it passes when run at the command line
  @ignore
  Scenario: deploys the library example, then checks if it's deployed.
    Given s2i build https://github.com/jboss-container-images/rhpam-7-openshift-image from quickstarts/library-process/library using rhpam71-dev
      | variable                        | value                                                                                    |
      | KIE_SERVER_CONTAINER_DEPLOYMENT | rhpam-kieserver-library=org.openshift.quickstarts:rhpam-kieserver-library:1.4.0-SNAPSHOT |
    Then container log should contain Container rhpam-kieserver-library

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
     And container log should contain -Dorg.jbpm.ejb.timer.tx=true
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

  Scenario: KIECLOUD-122 - Enable JMS for RHDM and RHPAM, verify if the JMS executor configuration
    When container is started with env
      | variable                           | value                             |
      | KIE_SERVER_JMS_QUEUE_EXECUTOR      | queue/KIE.SERVER.EXECUTOR.CUSTOM  |
      | KIE_SERVER_EXECUTOR_JMS_TRANSACTED | true                              |
    Then container log should contain -Dorg.kie.executor.jms=true
     And container log should contain -Dorg.kie.executor.jms.queue=queue/KIE.SERVER.EXECUTOR.CUSTOM
     And container log should contain -Dorg.kie.executor.jms.transacted=true
     And container log should contain Executor JMS based support successfully activated on queue ActiveMQQueue[jms.queue.KIE.SERVER.EXECUTOR]

    Scenario: Checks if the EJB Timer was successfully configured with MySQL with DB_SERVICE_PREFIX_MAPPING env
      When container is started with env
        | variable                   | value                            |
        | DB_SERVICE_PREFIX_MAPPING  | kie-app-mysql=DB                 |
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
      And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PinGlobalTxToPhysicalConnection"]
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
      And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='validation']/*[local-name()='validate-on-match']
      And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='validation']/*[local-name()='background-validation']
      And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLValidConnectionChecker on XPath //*[local-name()='validation']/*[local-name()='valid-connection-checker']/@class-name
      And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLExceptionSorter on XPath //*[local-name()='validation']/*[local-name()='exception-sorter']/@class-name

  Scenario: Checks if the EJB Timer was successfully configured with PostgreSQL with DB_SERVICE_PREFIX_MAPPING env
    When container is started with env
      | variable                                  | value                            |
      | DB_SERVICE_PREFIX_MAPPING                 | kie-app-postgresql=DB            |
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
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='validation']/*[local-name()='validate-on-match']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='validation']/*[local-name()='background-validation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.postgres.PostgreSQLValidConnectionChecker on XPath //*[local-name()='validation']/*[local-name()='valid-connection-checker']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.postgres.PostgreSQLExceptionSorter on XPath //*[local-name()='validation']/*[local-name()='exception-sorter']/@class-name

  Scenario: Checks if the EJB Timer was successfully configured with PostgreSQL with DATASOURCES env
    When container is started with env
      | variable                                  | value      |
      | DATASOURCES                               | TEST       |
      | TEST_DATABASE                             | bpms       |
      | TEST_USERNAME                             | bpmUser    |
      | TEST_PASSWORD                             | bpmPass    |
      | TEST_DRIVER                               | postgresql |
      | TEST_SERVICE_HOST                         | 10.1.1.1   |
      | TEST_SERVICE_PORT                         | 5432       |
      | TEST_NONXA                                | true       |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000      |
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

  Scenario: Checks if the EJB Timer was successfully configured with MySQL XA with DATASOURCES env
    When container is started with env
      | variable                                  | value      |
      | DATASOURCES                               | TEST       |
      | TEST_USERNAME                             | bpmUser    |
      | TEST_PASSWORD                             | bpmPass    |
      | TEST_DRIVER                               | mysql      |
      | TEST_XA_CONNECTION_PROPERTY_ServerName    | 10.1.1.1   |
      | TEST_XA_CONNECTION_PROPERTY_DatabaseName  | bpms       |
      | TEST_XA_CONNECTION_PROPERTY_Port          | 3306       |
      | TEST_NONXA                                | false      |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000      |
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
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PinGlobalTxToPhysicalConnection"]
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
     And container log should not contain WARN Missing configuration for XA datasource EJB_TIMER

  Scenario: Checks if the EJB Timer was successfully configured with MySQL with DATASOURCES env
    When container is started with env
      | variable                                  | value      |
      | DATASOURCES                               | TEST       |
      | TEST_DATABASE                             | bpms       |
      | TEST_USERNAME                             | bpmUser    |
      | TEST_PASSWORD                             | bpmPass    |
      | TEST_DRIVER                               | mysql      |
      | TEST_SERVICE_HOST                         | 10.1.1.1   |
      | TEST_SERVICE_PORT                         | 3306       |
      | TEST_NONXA                                | true       |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000      |
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
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PinGlobalTxToPhysicalConnection"]
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
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PinGlobalTxToPhysicalConnection"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/bpms on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
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
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/bpms?pinGlobalTxToPhysicalConnection=true on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/bpms on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
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
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/bpms?pinGlobalTxToPhysicalConnection=true on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/bpms on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
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
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PinGlobalTxToPhysicalConnection"]
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/myJndi_EJBTimer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='database-data-store']/@database
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval

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
      | variable                                  | value                           |
      | DATASOURCES                               | TEST                            |
      | TEST_USERNAME                             | bpmUser                         |
      | TEST_PASSWORD                             | bpmPass                         |
      | TEST_DRIVER                               | db2                             |
      | TEST_URL                                  | jdbc:db2://localhost            |
      | TEST_NONXA                                | true                            |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:db2://localhost on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 4 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DriverType"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:db2://localhost on XPath //*[local-name()='datasource']/*[local-name()='connection-url']

  Scenario: Checks if the EJB Timer was successfully configured for an external DB2 datasource with Type 2 and env using XA connection properties
    When container is started with env
      | variable                                  | value                           |
      | DATASOURCES                               | TEST                            |
      | TEST_USERNAME                             | bpmUser                         |
      | TEST_PASSWORD                             | bpmPass                         |
      | TEST_DRIVER                               | db2                             |
      | TEST_XA_CONNECTION_PROPERTY_URL           | jdbc:db2://localhost            |
      | TEST_NONXA                                | false                           |
      | TEST_DRIVER_TYPE                          | 2                               |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:db2://localhost on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 2 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DriverType"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:db2://localhost on XPath //*[local-name()='datasource']/*[local-name()='connection-url']

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
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mariadb://10.1.1.1:3306/bpms on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
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
      | TEST_XA_CONNECTION_PROPERTY_PortNumber    | 3306         |
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
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 3306 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PortNumber"]
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

  Scenario: Checks if the EJB Timer and common datasource were created
    When container is started with env
      | variable                         | value                                  |
      | DATASOURCES                      | RHPAM                                  |
      | RHPAM_DATABASE                   | rhpam7                                 |
      | RHPAM_JNDI                       | java:jboss/datasources/rhpam          |
      | RHPAM_JTA                        | true                                   |
      | RHPAM_DRIVER                     | h2                                     |
      | RHPAM_USERNAME                   | sa                                     |
      | RHPAM_PASSWORD                   | 123456                                 |
      | RHPAM_XA_CONNECTION_PROPERTY_URL | jdbc:h2:/opt/eap/standalone/data/rhpam |
      | RHPAM_SERVICE_HOST               | dummy                                  |
      | RHPAM_SERVICE_PORT               | 12345                                  |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/rhpam on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value rhpam-RHPAM on XPath //*[local-name()='datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value h2 on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:h2:/opt/eap/standalone/data/rhpam on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/rhpam_EJBTimer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:h2:/opt/eap/standalone/data/rhpam on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value sa on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 123456 on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/rhpam_EJBTimer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value h2 on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value -1 on XPath //*[local-name()='database-data-store']/@refresh-interval
