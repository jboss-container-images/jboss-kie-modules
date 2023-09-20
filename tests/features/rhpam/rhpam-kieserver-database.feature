@rhpam-7/rhpam-kieserver-rhel8
Feature: RHPAM KIE Server Database configuration tests

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
      | TEST_URL                                  | jdbc:postgresql://10.1.1.1:3306/bpms?ssl=true&sslmode=allow       |
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
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <connection-url>jdbc:mysql://10.1.1.1:3306/bpms?enabledTLSProtocols=TLSv1.2</connection-url>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="PinGlobalTxToPhysicalConnection">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="EnabledTLSProtocols">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="DatabaseName">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="Port">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="ServerName">

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
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain xa-datasource-property name="URL"><![CDATA[jdbc:mysql://10.1.1.1:3306/bpms?pinGlobalTxToPhysicalConnection=true&enabledTLSProtocols=TLSv1.2]]></xa-datasource-property>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="PinGlobalTxToPhysicalConnection">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="EnabledTLSProtocols">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="DatabaseName">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="Port">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="ServerName">
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
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <connection-url>jdbc:mysql://10.1.1.1:3306/bpms?enabledTLSProtocols=TLSv1.2</connection-url>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="PinGlobalTxToPhysicalConnection">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="EnabledTLSProtocols">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="DatabaseName">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="Port">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="ServerName">
    And container log should not contain WARN Missing configuration for XA datasource EJB_TIMER

  Scenario: Checks if the EJB Timer was successfully configured with MariaDB with DATASOURCES env with validation properties
    When container is started with env
      | variable                                  | value                                                                     |
      | DATASOURCES                               | TEST                                                                      |
      | TEST_DATABASE                             | bpms                                                                      |
      | TEST_USERNAME                             | bpmUser                                                                   |
      | TEST_PASSWORD                             | bpmPass                                                                   |
      | TEST_DRIVER                               | mariadb                                                                   |
      | TEST_SERVICE_HOST                         | 10.1.1.1                                                                  |
      | TEST_SERVICE_PORT                         | 3306                                                                      |
      | TEST_NONXA                                | true                                                                      |
      | TEST_BACKGROUND_VALIDATION                | false                                                                     |
      | TEST_CONNECTION_CHECKER                   | org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLValidConnectionChecker  |
      | TEST_EXCEPTION_SORTER                     | org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLExceptionSorter         |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000                                                                     |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mariadb on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
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
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='validation']/*[local-name()='validate-on-match']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='validation']/*[local-name()='background-validation']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLValidConnectionChecker on XPath //*[local-name()='validation']/*[local-name()='valid-connection-checker']/@class-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLExceptionSorter on XPath //*[local-name()='validation']/*[local-name()='exception-sorter']/@class-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mariadb://10.1.1.1:3306/bpms?pinGlobalTxToPhysicalConnection=true&enabledSslProtocolSuites=TLSv1.2 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Url"]
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <connection-url>jdbc:mariadb://10.1.1.1:3306/bpms?enabledSslProtocolSuites=TLSv1.2</connection-url>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="PinGlobalTxToPhysicalConnection">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="EnabledTLSProtocols">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="DatabaseName">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="Port">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="ServerName">
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
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="DatabaseName">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="Port">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="ServerName">
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
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <connection-url>jdbc:mysql://10.1.1.1:3306/bpms?enabledTLSProtocols=TLSv1.2</connection-url>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="PinGlobalTxToPhysicalConnection">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="EnabledTLSProtocols">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="DatabaseName">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="Port">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="ServerName">

  Scenario: Checks if the EJB Timer was successfully configured with MariaDB with DB_SERVICE_PREFIX_MAPPING env
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
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <connection-url>jdbc:mariadb://10.1.1.1:3306/bpms?enabledSslProtocolSuites=TLSv1.2</connection-url>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="PinGlobalTxToPhysicalConnection">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="EnabledSslProtocolSuites">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="DatabaseName">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="Port">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="ServerName">

  Scenario: Checks if the EJB Timer was successfully configured with MariaDB with XA DATASOURCES env with defaults and refresh interval
    When container is started with env
      | variable                                  | value      |
      | DATASOURCES                               | TEST       |
      | TEST_DATABASE                             | bpms       |
      | TEST_USERNAME                             | bpmUser    |
      | TEST_PASSWORD                             | bpmPass    |
      | TEST_DRIVER                               | mariadb    |
      | TEST_SERVICE_HOST                         | 10.1.1.1   |
      | TEST_SERVICE_PORT                         | 3306       |
      | TEST_NONXA                                | false      |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 10000      |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='xa-datasource']/@jndi-name
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <xa-datasource-property name="Url">jdbc:mariadb://10.1.1.1:3306/bpms?pinGlobalTxToPhysicalConnection=true&amp;enabledSslProtocolSuites=TLSv1.2</xa-datasource-property>
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mariadb on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
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
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <connection-url>jdbc:mariadb://10.1.1.1:3306/bpms?enabledSslProtocolSuites=TLSv1.2</connection-url>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="PinGlobalTxToPhysicalConnection">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="EnabledSslProtocolSuites">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="DatabaseName">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="Port">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="ServerName">
    And container log should not contain WARN Missing configuration for XA datasource EJB_TIMER

  Scenario: Checks if the EJB Timer was successfully configured with MariaDB with DATASOURCES and XA Properties
    When container is started with env
      | variable                                                     | value                     |
      | DATASOURCES                                                  | TEST                      |
      | TEST_USERNAME                                                | bpmUser                   |
      | TEST_PASSWORD                                                | bpmPass                   |
      | TEST_DRIVER                                                  | mariadb                   |
      | TEST_XA_CONNECTION_PROPERTY_ServerName                       | 10.1.1.1                  |
      | TEST_XA_CONNECTION_PROPERTY_Port                             | 3306                      |
      | TEST_XA_CONNECTION_PROPERTY_DatabaseName                     | bpms                      |
      | TEST_XA_CONNECTION_PROPERTY_JNDI                             | jboss:/datasources/rhpam  |
      | TEST_XA_CONNECTION_PROPERTY_EnabledSslProtocolSuites         | TLSv1.2                   |
      | TEST_XA_CONNECTION_PROPERTY_PinGlobalTxToPhysicalConnection  | true                      |
      | TEST_XA_CONNECTION_PROPERTY_Test                             | true                      |
      | TEST_NONXA                                                   | false                     |
      | TEST_JTA                                                     | true                      |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='xa-datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Test"]
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='validate-on-match']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='background-validation']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLValidConnectionChecker on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='valid-connection-checker']/@class-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLExceptionSorter on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='exception-sorter']/@class-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mariadb on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mariadb on XPath //*[local-name()='database-data-store']/@database
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value -1 on XPath //*[local-name()='database-data-store']/@refresh-interval
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='min-pool-size']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-pool']/*[local-name()='max-pool-size']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mariadb://10.1.1.1:3306/bpms?pinGlobalTxToPhysicalConnection=true&enabledSslProtocolSuites=TLSv1.2 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Url"]
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <connection-url>jdbc:mariadb://10.1.1.1:3306/bpms?enabledSslProtocolSuites=TLSv1.2</connection-url>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="JNDI">jboss:/datasources/rhpam</xa-datasource-property>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="PinGlobalTxToPhysicalConnection">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="EnabledSslProtocolSuites">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="DatabaseName">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="Port">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <xa-datasource-property name="ServerName">
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

  Scenario: Checks if the EJB Timer was successfully configured with MariaDB with non XA DATASOURCES env
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
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain value 3306 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Port"]
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain value bpms on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]

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
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain value 127.0.0.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain value 3306 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Port"]
  @wip
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