@rhpam-7/rhpam70-kieserver-openshift
Feature: RHPAM KIE Server configuration tests

  # https://issues.jboss.org/browse/CLOUD-180
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain rhpam-7/rhpam70-kieserver-openshift image, version

  Scenario: Check for product and version environment variables
    When container is ready
    Then run sh -c 'echo $JBOSS_PRODUCT' in container and check its output for rhpam-kieserver
     And run sh -c 'echo $RHPAM_KIESERVER_VERSION' in container and check its output for 7.0.0

  # https://issues.jboss.org/browse/RHPAM-891
  Scenario: Check default users are properly configured
    When container is ready
    Then file /opt/eap/standalone/configuration/application-users.properties should contain adminUser=de3155e1927c6976555925dec24a53ac
     And file /opt/eap/standalone/configuration/application-roles.properties should contain adminUser=kie-server,rest-all,admin,kiemgmt,Administrators
     And file /opt/eap/standalone/configuration/application-users.properties should not contain mavenUser
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain mavenUser
     And file /opt/eap/standalone/configuration/application-users.properties should not contain controllerUser
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain controllerUser
     And file /opt/eap/standalone/configuration/application-users.properties should contain executionUser=69ea96114cd41afa6a9d5be2e1e0531e
     And file /opt/eap/standalone/configuration/application-roles.properties should contain executionUser=kie-server,rest-all,guest

  # https://issues.jboss.org/browse/RHPAM-891
  Scenario: Check custom users are properly configured
    When container is started with env
      | variable                   | value       |
      | KIE_ADMIN_USER             | customAdm   |
      | KIE_ADMIN_PWD              | customAdm!0 |
      | KIE_MAVEN_USER             | customMvn   |
      | KIE_MAVEN_PWD              | customMvn!0 |
      | KIE_SERVER_CONTROLLER_USER | customCtl   |
      | KIE_SERVER_CONTROLLER_PWD  | customCtl!0 |
      | KIE_SERVER_USER            | customExe   |
      | KIE_SERVER_PWD             | customExe!0 |
    Then file /opt/eap/standalone/configuration/application-users.properties should contain customAdm=05ad559f03f4a06845bf201990f6832f
     And file /opt/eap/standalone/configuration/application-roles.properties should contain customAdm=kie-server,rest-all,admin,kiemgmt,Administrators
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customMvn
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customMvn
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customCtl
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customCtl
     And file /opt/eap/standalone/configuration/application-users.properties should contain customExe=e37e2a53d5e3bef041d07263fb84f0de
     And file /opt/eap/standalone/configuration/application-roles.properties should contain customExe=kie-server,rest-all,guest

  Scenario: Test REST API is available and valid
    When container is started with env
      | variable         | value       |
      | KIE_SERVER_USER  | kieserver   |
      | KIE_SERVER_PWD   | kieserver1! |
    Then check that page is served
      | property        | value                 |
      | port            | 8080                  |
      | path            | /services/rest/server |
      | wait            | 60                    |
      | username        | kieserver             |
      | password        | kieserver1!           |
      | expected_phrase | SUCCESS               |

  # https://issues.jboss.org/browse/CLOUD-1145 - base test
  Scenario: Check custom war file was successfully deployed via CUSTOM_INSTALL_DIRECTORIES
    Given s2i build https://github.com/jboss-openshift/openshift-examples.git from custom-install-directories
      | variable   | value                    |
      | CUSTOM_INSTALL_DIRECTORIES | custom   |
    Then file /opt/eap/standalone/deployments/node-info.war should exist

  Scenario: deploys the library example, then checks if it's deployed.
    Given s2i build https://github.com/jboss-container-images/rhpam-7-openshift-image from quickstarts/library-process/library using rhpam70-dev
      | variable                        | value                                                                                    |
      | KIE_SERVER_CONTAINER_DEPLOYMENT | rhpam-kieserver-library=org.openshift.quickstarts:rhpam-kieserver-library:1.4.0-SNAPSHOT |
    Then container log should contain Container rhpam-kieserver-library


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
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value kie_app_mysql-DB on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS_EJBTimer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/bpms?pinGlobalTxToPhysicalConnection=true on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS_EJBTimer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='database-data-store']/@database
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition

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
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value kie_app_postgresql-DB on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value kie_app_postgresql-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
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
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
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
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/bpms?pinGlobalTxToPhysicalConnection=true on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
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
   Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/myJndi on XPath //*[local-name()='xa-datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='datasource']/@enabled
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='datasource']/@use-java-context
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER on XPath //*[local-name()='xa-datasource']/@pool-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='xa-datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@use-java-context
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/@enabled
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/bpms?pinGlobalTxToPhysicalConnection=true on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmUser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value bpmPass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_READ_COMMITTED on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='timer-service']/@default-data-store
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_ds on XPath //*[local-name()='database-data-store']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ejb_timer on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='database-data-store']/@database
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ejb_timer-EJB_TIMER_part on XPath //*[local-name()='database-data-store']/@partition
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='database-data-store']/@refresh-interval

  Scenario: Checks if the EJB Timer was successfully configured using external datasource with DATASOURCES env using XA URL property
    When container is started with env
      | variable                                  | value                                                                       |
      | DATASOURCES                               | TEST                                                                        |
      | TEST_USERNAME                             | bpmUser                                                                     |
      | TEST_PASSWORD                             | bpmPass                                                                     |
      | TEST_DRIVER                               | oracle                                                                      |
      | TEST_XA_CONNECTION_PROPERTY_URL           | jdbc:oracle:thin:@test.com:1521:bpms                                        |
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
