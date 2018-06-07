@jboss-processserver-6/processserver64-openshift @wip
Feature: OpenShift Process Server 6.4 basic tests

  Scenario: Check for add-user failures
    When container is ready
    Then container log should contain Running jboss-processserver-6/processserver64-openshift image
     And available container log should not contain AddUserFailedException

  Scenario: Check for product and version  environment variables
    When container is ready
    Then run sh -c 'echo $JBOSS_PRODUCT' in container and check its output for processserver
     And run sh -c 'echo $JBOSS_PROCESSSERVER_VERSION' in container and check its output for 6.4

  Scenario: Checks if the kie-server webapp is deployed.
    When container is ready
    Then container log should contain Deployed "kie-server.war"

  Scenario: Test REST API is secure
    When container is ready
    Then check that page is served
      | property | value |
      | port     | 8080  |
      | path     | /kie-server/services/rest/server |
      | expected_status_code | 401 |

  Scenario: Test REST API is available and valid
    When container is ready
    Then check that page is served
      | property | value |
      | port     | 8080  |
      | path     | /kie-server/services/rest/server |
      | username | kieserver |
      | password | kieserver1! |
      | expected_phrase | SUCCESS |

  Scenario: Checks SQL Importer behaviour if QUARTZ_JNDI variable does not exists
    When container is ready
    Then container log should contain QUARTZ_JNDI env not found, skipping SqlImporter

  Scenario: Checks if the Quartz was successfully configured with MySQL
    When container is started with env
      | variable                        | value                                      |
      | DB_SERVICE_PREFIX_MAPPING       | kie-app-mysql=DB,kie-app-mysql=QUARTZ      |
      | DB_DATABASE                     | mydb                                       |
      | DB_USERNAME                     | root                                       |
      | DB_PASSWORD                     | password                                   |
      | DB_JNDI                         | java:jboss/datasources/ExampleDS           |
      | QUARTZ_JNDI                     | java:jboss/datasources/ExampleDSNotManaged |
      | QUARTZ_DATABASE                 | mydb                                       |
      | QUARTZ_USERNAME                 | root                                       |
      | QUARTZ_PASSWORD                 | password                                   |
      | QUARTZ_JTA                      | false                                      |
      | QUARTZ_NONXA                    | true                                       |
      | KIE_APP_MYSQL_SERVICE_HOST      | 10.1.1.1                                   |
      | KIE_APP_MYSQL_SERVICE_PORT      | 3306                                       |
      | KIE_SERVER_PERSISTENCE_DIALECT  | org.hibernate.dialect.MySQLDialect         |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDSNotManaged on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='datasource']/@jta
     And container log should contain Starting SqlImporter...

  Scenario: Checks if the Quartz was successfully configured with MySQL with DATASOURCE env
    When container is started with env
      | variable                        | value                                      |
      | DATASOURCES                     | DB,QUARTZ                                  |
      | DB_DRIVER                       | mysql                                      |
      | DB_DATABASE                     | mydb                                       |
      | DB_USERNAME                     | root                                       |
      | DB_PASSWORD                     | password                                   |
      | DB_SERVICE_HOST                 | 10.1.1.1                                   |
      | DB_SERVICE_PORT                 | 3306                                       |
      | DB_JNDI                         | java:jboss/datasources/ExampleDS           |
      | QUARTZ_DRIVER                   | mysql                                      |
      | QUARTZ_JNDI                     | java:jboss/datasources/ExampleDSNotManaged |
      | QUARTZ_DATABASE                 | mydb                                       |
      | QUARTZ_USERNAME                 | root                                       |
      | QUARTZ_PASSWORD                 | password                                   |
      | QUARTZ_JTA                      | false                                      |
      | QUARTZ_NONXA                    | true                                       |
      | QUARTZ_SERVICE_HOST             | 10.1.1.1                                   |
      | QUARTZ_SERVICE_PORT             | 3306                                       |
      | KIE_SERVER_PERSISTENCE_DIALECT  | org.hibernate.dialect.MySQLDialect         |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDSNotManaged on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='datasource']/@jta
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLValidConnectionChecker on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='valid-connection-checker']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLExceptionSorter on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='exception-sorter']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='validate-on-match']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='background-validation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLValidConnectionChecker on XPath //*[local-name()='xa-datasource']//*[local-name()='validation']/*[local-name()='valid-connection-checker']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLExceptionSorter on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='exception-sorter']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='validate-on-match']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='background-validation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='driver']/@name
     And container log should contain Starting SqlImporter...

  Scenario: Checks if the Quartz was successfully configured with PostgreSQL
    When container is started with env
      | variable                        | value                                           |
      | DB_SERVICE_PREFIX_MAPPING       | kie-app-postgresql=DB,kie-app-postgresql=QUARTZ |
      | DB_DATABASE                     | mydb                                            |
      | DB_USERNAME                     | root                                            |
      | DB_PASSWORD                     | password                                        |
      | DB_JNDI                         | java:jboss/datasources/ExampleDS                |
      | QUARTZ_JNDI                     | java:jboss/datasources/ExampleDSNotManaged      |
      | QUARTZ_DATABASE                 | mydb                                            |
      | QUARTZ_USERNAME                 | root                                            |
      | QUARTZ_PASSWORD                 | password                                        |
      | QUARTZ_JTA                      | false                                           |
      | QUARTZ_NONXA                    | true                                            |
      | KIE_APP_POSTGRESQL_SERVICE_HOST | 10.1.1.1                                        |
      | KIE_APP_POSTGRESQL_SERVICE_PORT | 5432                                            |
      | KIE_SERVER_PERSISTENCE_DIALECT  | org.hibernate.dialect.MySQL82Dialect            |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql on XPath //*[local-name()='datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDSNotManaged on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='datasource']/@jta
     And container log should contain Starting SqlImporter...

  Scenario: Checks if the Quartz was successfully configured with PostgreSQL env DATASOURCE env
    When container is started with env
      | variable                        | value                                      |
      | DATASOURCES                     | DB,QUARTZ                                  |
      | DB_DRIVER                       | postgresql                                 |
      | DB_DATABASE                     | mydb                                       |
      | DB_USERNAME                     | root                                       |
      | DB_PASSWORD                     | password                                   |
      | DB_SERVICE_HOST                 | 10.1.1.1                                   |
      | DB_SERVICE_PORT                 | 5432                                       |
      | DB_JNDI                         | java:jboss/datasources/ExampleDS           |
      | QUARTZ_DRIVER                   | postgresql                                 |
      | QUARTZ_JNDI                     | java:jboss/datasources/ExampleDSNotManaged |
      | QUARTZ_DATABASE                 | mydb                                       |
      | QUARTZ_USERNAME                 | root                                       |
      | QUARTZ_PASSWORD                 | password                                   |
      | QUARTZ_JTA                      | false                                      |
      | QUARTZ_NONXA                    | true                                       |
      | QUARTZ_SERVICE_HOST             | 10.1.1.1                                   |
      | QUARTZ_SERVICE_PORT             | 5432                                       |
      | KIE_SERVER_PERSISTENCE_DIALECT  | org.hibernate.dialect.MySQL82Dialect       |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql on XPath //*[local-name()='datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDSNotManaged on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='datasource']/@jta
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.postgres.PostgreSQLValidConnectionChecker on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='valid-connection-checker']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.postgres.PostgreSQLExceptionSorter on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='exception-sorter']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='validate-on-match']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='background-validation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.postgres.PostgreSQLValidConnectionChecker on XPath //*[local-name()='xa-datasource']//*[local-name()='validation']/*[local-name()='valid-connection-checker']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.jboss.jca.adapters.jdbc.extensions.postgres.PostgreSQLExceptionSorter on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='exception-sorter']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='validate-on-match']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='background-validation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='driver']/@name
     And container log should contain Starting SqlImporter...

  Scenario: Checks if the Quartz was successfully configured with Oracle db
    When container is started with env
      | variable                        | value                                     |
      | DATASOURCES                     | DB,QUARTZ                                 |
      | DB_JNDI                         | java:jboss/datasources/jbpmDS             |
      | DB_XA_CONNECTION_PROPERTY_URL   | jdbc:oracle:thin:@10.1.1.1:1521:jbpm      |
      | DB_USERNAME                     | root                                      |
      | DB_PASSWORD                     | password                                  |
      | DB_NONXA                        | false                                     |
      | DB_DRIVER                       | oracle                                    |
      | DB_CONNECTION_CHECKER           | OracleValidConnectionChecker              |
      | DB_EXCEPTION_SORTER             | OracleExceptionSorter                     |
      | DB_BACKGROUND_VALIDATION        | true                                      |
      | QUARTZ_JNDI                     | java:jboss/datasources/jbpmDSNotManaged   |
      | QUARTZ_URL                      | jdbc:oracle:thin:@10.1.1.1:1521:jbpm      |
      | QUARTZ_DATABASE                 | mydb                                      |
      | QUARTZ_USERNAME                 | root                                      |
      | QUARTZ_PASSWORD                 | password                                  |
      | QUARTZ_JTA                      | false                                     |
      | QUARTZ_NONXA                    | true                                      |
      | QUARTZ_DRIVER                   | oracle                                    |
      | QUARTZ_DRIVER_MODULE            | com.oracle                                |
      | QUARTZ_CONNECTION_CHECKER       | OracleValidConnectionChecker              |
      | QUARTZ_EXCEPTION_SORTER         | OracleExceptionSorter                     |
      | QUARTZ_BACKGROUND_VALIDATION    | true                                      |
      | KIE_SERVER_PERSISTENCE_DIALECT  | org.hibernate.dialect.Oracle10gDialect    |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value oracle on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value oracle on XPath //*[local-name()='datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:oracle:thin:@10.1.1.1:1521:jbpm on XPath  //*[local-name()='datasource']/*[local-name()='connection-url']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:oracle:thin:@10.1.1.1:1521:jbpm on XPath  //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/jbpmDS on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/jbpmDSNotManaged on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='datasource']/@jta
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value OracleValidConnectionChecker on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='valid-connection-checker']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value OracleExceptionSorter on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='exception-sorter']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='validate-on-match']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='background-validation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='background-validation-millis']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value OracleValidConnectionChecker on XPath //*[local-name()='xa-datasource']//*[local-name()='validation']/*[local-name()='valid-connection-checker']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value OracleExceptionSorter on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='exception-sorter']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='validate-on-match']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='background-validation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='background-validation-millis']
     And file /opt/eap/standalone/deployments/kie-server.war/WEB-INF/jboss-deployment-structure.xml should contain <module name="com.oracle"/>

  Scenario: Checks if the Quartz was successfully configured with oracle d
    When container is started with env
      | variable                        | value                                     |
      | DATASOURCES                     | DB,QUARTZ                                 |
      | DB_JNDI                         | java:jboss/datasources/jbpmDS             |
      | DB_XA_CONNECTION_PROPERTY_URL   | jdbc:oracle:thin:@10.1.1.1:1521:jbpm      |
      | DB_USERNAME                     | root                                      |
      | DB_PASSWORD                     | password                                  |
      | DB_DRIVER                       | oracle                                    |
      | DB_CONNECTION_CHECKER           | OracleValidConnectionChecker              |
      | DB_EXCEPTION_SORTER             | OracleExceptionSorter                     |
      | DB_BACKGROUND_VALIDATION        | true                                      |
      | QUARTZ_JNDI                     | java:jboss/datasources/jbpmDSNotManaged   |
      | QUARTZ_URL                      | jdbc:oracle:thin:@10.1.1.1:1521:jbpm      |
      | QUARTZ_DATABASE                 | mydb                                      |
      | QUARTZ_USERNAME                 | root                                      |
      | QUARTZ_PASSWORD                 | password                                  |
      | QUARTZ_JTA                      | false                                     |
      | QUARTZ_NONXA                    | true                                      |
      | QUARTZ_DRIVER                   | oracle                                    |
      | QUARTZ_DRIVER_MODULE            | deployment.ojdbc6.jar                     |
      | QUARTZ_CONNECTION_CHECKER       | OracleValidConnectionChecker              |
      | QUARTZ_EXCEPTION_SORTER         | OracleExceptionSorter                     |
      | QUARTZ_BACKGROUND_VALIDATION    | true                                      |
      | KIE_SERVER_PERSISTENCE_DIALECT  | org.hibernate.dialect.Oracle10gDialect    |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value oracle on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value oracle on XPath //*[local-name()='datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:oracle:thin:@10.1.1.1:1521:jbpm on XPath  //*[local-name()='datasource']/*[local-name()='connection-url']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:oracle:thin:@10.1.1.1:1521:jbpm on XPath  //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/jbpmDS on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/jbpmDSNotManaged on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='datasource']/@jta
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value OracleValidConnectionChecker on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='valid-connection-checker']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value OracleExceptionSorter on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='exception-sorter']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='validate-on-match']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='background-validation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='background-validation-millis']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value OracleValidConnectionChecker on XPath //*[local-name()='xa-datasource']//*[local-name()='validation']/*[local-name()='valid-connection-checker']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value OracleExceptionSorter on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='exception-sorter']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='validate-on-match']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='background-validation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='background-validation-millis']
     And file /opt/eap/standalone/deployments/kie-server.war/WEB-INF/jboss-deployment-structure.xml should contain <module name="deployment.ojdbc6.jar"/>

  Scenario: Checks if the Quartz was successfully configured with db2 with no schema
    When container is started with env
      | variable                        | value                                     |
      | DATASOURCES                     | DB,QUARTZ                                 |
      | DB_JNDI                         | java:jboss/datasources/jbpmDS             |
      | DB_XA_CONNECTION_PROPERTY_URL   | jdbc:db2://myhost:5021/jbpm               |
      | DB_USERNAME                     | root                                      |
      | DB_PASSWORD                     | password                                  |
      | DB_DRIVER                       | db2                                       |
      | DB_CONNECTION_CHECKER           | DB2ValidConnectionChecker                 |
      | DB_EXCEPTION_SORTER             | DB2ExceptionSorter                        |
      | DB_BACKGROUND_VALIDATION        | true                                      |
      | QUARTZ_JNDI                     | java:jboss/datasources/jbpmDSNotManaged   |
      | QUARTZ_URL                      | jdbc:db2://myhost:5021/jbpm               |
      | QUARTZ_DATABASE                 | mydb                                      |
      | QUARTZ_USERNAME                 | root                                      |
      | QUARTZ_PASSWORD                 | password                                  |
      | QUARTZ_JTA                      | false                                     |
      | QUARTZ_NONXA                    | true                                      |
      | QUARTZ_DRIVER                   | db2                                       |
      | QUARTZ_CONNECTION_CHECKER       | DB2ValidConnectionChecker                 |
      | QUARTZ_EXCEPTION_SORTER         | DB2ExceptionSorter                        |
      | QUARTZ_BACKGROUND_VALIDATION    | true                                      |
      | KIE_SERVER_PERSISTENCE_DIALECT  | org.hibernate.dialect.DB2Dialect          |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:db2://myhost:5021/jbpm on XPath  //*[local-name()='datasource']/*[local-name()='connection-url']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:db2://myhost:5021/jbpm on XPath  //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/jbpmDS on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/jbpmDSNotManaged on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='datasource']/@jta
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value DB2ValidConnectionChecker on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='valid-connection-checker']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value DB2ExceptionSorter on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='exception-sorter']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='validate-on-match']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='background-validation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='background-validation-millis']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value DB2ValidConnectionChecker on XPath //*[local-name()='xa-datasource']//*[local-name()='validation']/*[local-name()='valid-connection-checker']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value DB2ExceptionSorter on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='exception-sorter']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='validate-on-match']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='background-validation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='background-validation-millis']

  Scenario: Checks if the Quartz was successfully configured with db2
    When container is started with env
      | variable                        | value                                     |
      | DATASOURCES                     | DB,QUARTZ                                 |
      | DB_JNDI                         | java:jboss/datasources/jbpmDS             |
      | DB_XA_CONNECTION_PROPERTY_URL   | jdbc:db2://myhost:5021/jbpm               |
      | DB_USERNAME                     | root                                      |
      | DB_PASSWORD                     | password                                  |
      | DB_DRIVER                       | db2                                       |
      | DB_CONNECTION_CHECKER           | DB2ValidConnectionChecker                 |
      | DB_EXCEPTION_SORTER             | DB2ExceptionSorter                        |
      | DB_BACKGROUND_VALIDATION        | true                                      |
      | QUARTZ_JNDI                     | java:jboss/datasources/jbpmDSNotManaged   |
      | QUARTZ_URL                      | jdbc:db2://myhost:5021/jbpm               |
      | QUARTZ_DATABASE                 | mydb                                      |
      | QUARTZ_USERNAME                 | root                                      |
      | QUARTZ_PASSWORD                 | password                                  |
      | QUARTZ_JTA                      | false                                     |
      | QUARTZ_NONXA                    | true                                      |
      | QUARTZ_DRIVER                   | db2                                       |
      | QUARTZ_CONNECTION_CHECKER       | DB2ValidConnectionChecker                 |
      | QUARTZ_EXCEPTION_SORTER         | DB2ExceptionSorter                        |
      | QUARTZ_BACKGROUND_VALIDATION    | true                                      |
      | KIE_SERVER_PERSISTENCE_DIALECT  | org.hibernate.dialect.DB2Dialect          |
      | KIE_SERVER_PERSISTENCE_SCHEMA   | my.schema                                 |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value db2 on XPath //*[local-name()='datasource']/*[local-name()='driver']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:db2://myhost:5021/jbpm on XPath  //*[local-name()='datasource']/*[local-name()='connection-url']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:db2://myhost:5021/jbpm on XPath  //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/jbpmDS on XPath //*[local-name()='xa-datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/jbpmDSNotManaged on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='datasource']/@jta
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value DB2ValidConnectionChecker on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='valid-connection-checker']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value DB2ExceptionSorter on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='exception-sorter']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='validate-on-match']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='background-validation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='datasource']/*[local-name()='validation']/*[local-name()='background-validation-millis']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value DB2ValidConnectionChecker on XPath //*[local-name()='xa-datasource']//*[local-name()='validation']/*[local-name()='valid-connection-checker']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value DB2ExceptionSorter on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='exception-sorter']/@class-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='validate-on-match']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='background-validation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='xa-datasource']/*[local-name()='validation']/*[local-name()='background-validation-millis']
     And container log should contain -Dorg.kie.server.persistence.schema=my.schema

  Scenario: check ownership when started as alternative UID
    When container is started as uid 26458
    Then container log should contain Running
     And run id -u in container and check its output contains 26458
     And all files under /opt/eap are writeable by current user
     And all files under /deployments are writeable by current user

  Scenario: Checks that CLOUD-1476 patch upgrade was successful
    When container is ready
    Then file /opt/eap/standalone/deployments/kie-server.war/WEB-INF/web.xml should contain org.openshift.kieserver
     And file /opt/eap/standalone/deployments/kie-server.war/WEB-INF/security-filter-rules.properties should exist
     And file /opt/eap/standalone/deployments/kie-server.war/WEB-INF/lib/kie-api-6.5.0.Final-redhat-2.jar should not exist
     And file /opt/eap/standalone/deployments/kie-server.war/WEB-INF/lib/kie-api-6.5.0.Final-redhat-21.jar should exist
     And file /opt/eap/standalone/deployments/kie-server.war/WEB-INF/lib/openshift-kieserver-common-1.2.2.Final-redhat-1.jar should exist
