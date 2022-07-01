@rhdm-7/rhdm-kieserver-rhel8  @rhpam-7/rhpam-kieserver-rhel8
Feature: Kie Server common features

  Scenario: RHPAM-2855: /opt/jboss/container/maven/default/ should not contain '*' and symlink /usr/local/s2i/scl-enable-maven should not exist
    When container is started with command bash
    Then run sh -c "test ! -L /opt/jboss/container/maven/default/'*' && echo all good" in container and check its output for all good
     And run sh -c 'test ! -L /usr/local/s2i/scl-enable-maven && echo all good' in container and check its output for all good

  Scenario: Test REST API is secure
    When container is ready
    Then check that page is served
      | property             | value                 |
      | port                 | 8080                  |
      | path                 | /services/rest/server |
      | expected_status_code | 401                   |

  Scenario: Check if kieserver mgmt is correctly set.
    When container is started with env
      | variable                   | value  |
      | KIE_SERVER_MGMT_DISABLED   | true   |
    Then container log should contain -Dorg.kie.server.mgmt.api.disabled=true

  Scenario: Test REST API is available and valid
    When container is started with env
      | variable         | value       |
      | KIE_ADMIN_ROLES  | kie-server  |
      | KIE_ADMIN_PWD    | kieserver1! |
    Then check that page is served
      | property        | value                 |
      | port            | 8080                  |
      | path            | /services/rest/server |
      | wait            | 80                    |
      | username        | adminUser             |
      | password        | kieserver1!           |
      | expected_phrase | SUCCESS               |

  Scenario: test KIE_MBEANS configuration
    When container is started with env
      | variable   | value |
      | KIE_MBEANS | false |
    Then container log should contain -Dkie.mbeans=disabled -Dkie.scanner.mbeans=disabled

  Scenario: Configure kie server to be immutable, disable management and set startup strategy
    When container is started with env
      | variable                    | value                          |
      | KIE_SERVER_MGMT_DISABLED    | true                           |
      | KIE_SERVER_STARTUP_STRATEGY | ControllerBasedStartupStrategy |
    Then container log should contain -Dorg.kie.server.mgmt.api.disabled=true
    And container log should contain -Dorg.kie.server.startup.strategy=ControllerBasedStartupStrategy

  Scenario: Configure kie server to be immutable, disable management and set a invalid startup strategy
    When container is started with env
      | variable                    | value    |
      | KIE_SERVER_MGMT_DISABLED    | true     |
      | KIE_SERVER_STARTUP_STRATEGY | invalid  |
    Then container log should contain -Dorg.kie.server.mgmt.api.disabled=true
    And container log should contain The startup strategy invalid is not valid, the valid strategies are LocalContainersStartupStrategy and ControllerBasedStartupStrategy

  Scenario: Test the KIE_SERVER_HOST configuration with custom host
    When container is started with env
      | variable           | value                      |
      | KIE_SERVER_HOST    | my-custon-host.example.com |
      | KIE_SERVER_PORT    | 80                         |
    Then container log should contain -Dorg.kie.server.location=http://my-custon-host.example.com:80/services/rest/server

  Scenario: Test the kie server location with hardcoded value
    When container is started with env
      | variable            | value                                  |
      | KIE_SERVER_LOCATION | https://foo.bar.com:9443/rest/endpoint |
    Then container log should contain -Dorg.kie.server.location=https://foo.bar.com:9443/rest/endpoint

  Scenario: Test the kie server location with legacy hardcoded url value
    When container is started with env
      | variable        | value                                     |
      | KIE_SERVER_URL  | http://bar.foo.io/rest/endpoints/serviceA |
      | KIE_SERVER_HOST | should.be.ignored                         |
    Then container log should contain -Dorg.kie.server.location=http://bar.foo.io/rest/endpoints/serviceA

  Scenario: Test the kie server location with custom build parameters
    When container is started with env
      | variable            | value   |
      | KIE_SERVER_PROTOCOL | ws      |
      | KIE_SERVER_HOST     | my-host |
      | KIE_SERVER_PORT     | 9080    |
    Then container log should contain -Dorg.kie.server.location=ws://my-host:9080/services/rest/server

  Scenario: Test the kie server location with custom insecure host
    When container is started with env
      | variable                         | value                      |
      | HOSTNAME_HTTP                    | my-custom-host.example.com |
      | KIE_SERVER_ROUTE_NAME            | my-custom-route            |
    Then container log should contain -Dorg.kie.server.location=http://my-custom-host.example.com:80/services/rest/server

  Scenario: Test the kie server location with custom secure host and secure route name
    When container is started with env
      | variable                         | value                      |
      | HOSTNAME_HTTPS                   | my-custom-host.example.com |
      | KIE_SERVER_ROUTE_NAME            | my-custom-route            |
      | KIE_SERVER_USE_SECURE_ROUTE_NAME | true                       |
    Then container log should contain -Dorg.kie.server.location=https://my-custom-host.example.com:443/services/rest/server

  Scenario: Test the KIE_SERVER_HOST configuration with custom host with default port
    When container is started with env
      | variable         | value                      |
      | KIE_SERVER_ID    | helloworld                 |
    Then container log should contain -Dorg.kie.server.id=helloworld

  Scenario: Test the KIE_SERVER_HOST with no value provided
    When container is ready
    Then container log should contain :8080/services/rest/server

  Scenario: Check if eap users are not being created if SSO is configured
    When container is started with env
      | variable                   | value         |
      | SSO_URL                    | http://url    |
      | KIE_ADMIN_USER             | customAdm     |
      | KIE_ADMIN_PWD              | custom" Adm!0 |
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain customAdm
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customAdm
     And container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain KIE_ADMIN_USER is set to customAdm, make sure to configure this user with the provided password on the external auth provider with the roles kie-server,rest-all,admin,kiemgmt,Administrators

  Scenario: Check if eap users are not being created if LDAP is configured
    When container is started with env
      | variable                   | value         |
      | AUTH_LDAP_URL              | ldap://url:389|
      | KIE_ADMIN_USER             | customAdm     |
      | KIE_ADMIN_PWD              | custom" Adm!0 |
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain customAdm
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customAdm
     And container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain KIE_ADMIN_USER is set to customAdm, make sure to configure this user with the provided password on the external auth provider with the roles kie-server,rest-all,admin,kiemgmt,Administrators

  Scenario: Check if eap users are not being created if LDAP is configured with no users env
    When container is started with env
      | variable                   | value         |
      | AUTH_LDAP_URL              | ldap://url:389|
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain adminUser
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain adminUser
     And container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain Make sure to configure KIE_ADMIN_USER user to access the application with the roles kie-server,rest-all,admin,kiemgmt,Administrators,user

  Scenario: Configure kie server to use LDAP authentication
    When container is started with env
      | variable                    | value                         |
      | AUTH_LDAP_URL               | test_url                      |
      | AUTH_LDAP_BIND_DN           | cn=Manager,dc=example,dc=com  |
      | AUTH_LDAP_BIND_CREDENTIAL   | admin                         |
      | AUTH_LDAP_BASE_CTX_DN       | ou=Users,dc=example,dc=com    |
      | AUTH_LDAP_BASE_FILTER       | uid                           |
      | AUTH_LDAP_ROLE_ATTRIBUTE_ID | cn                            |
      | AUTH_LDAP_ROLES_CTX_DN      | ou=Roles,dc=example,dc=com    |
      | AUTH_LDAP_ROLE_FILTER       | (member={1})                  |
    Then container log should contain AUTH_LDAP_URL is set to [test_url], setting up LDAP authentication with elytron...
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain  <dir-context name="KIELdapDC" url="test_url" principal="cn=Manager,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <credential-reference clear-text="admin"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <attribute from="cn" to="Roles" filter="(member={1})" filter-base-dn="ou=Roles,dc=example,dc=com"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <identity-mapping rdn-identifier="uid" search-base-dn="ou=Users,dc=example,dc=com">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security-domain name="KIELdapSecurityDomain" default-realm="KIELdapRealm" permission-mapper="default-permission-mapper">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <security elytron-domain="KIELdapSecurityDomain"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <application-security-domain name="other" security-domain="KIELdapSecurityDomain"/>
    And file /opt/eat/standalone/deploy/ROOT/WEB-INF/jboss-web.xml should not contain <security-domain>other</security-domain>

  Scenario: Don't configure kie server to use LDAP authentication
    When container is ready
    Then container log should contain AUTH_LDAP_URL not set. Skipping LDAP integration...
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <dir-context name="KIELdapDC" url="test_url"

  Scenario: Test custom role mapper
    When container is started with env
      | variable                           | value                        |
      | AUTH_LDAP_URL                      | test_url                     |
      | AUTH_LDAP_BIND_DN                  | cn=Manager,dc=example,dc=com |
      | AUTH_LDAP_BIND_CREDENTIAL          | admin                        |
      | AUTH_LDAP_BASE_CTX_DN              | ou=Users,dc=example,dc=com   |
      | AUTH_LDAP_BASE_FILTER              | uid                          |
      | AUTH_LDAP_ROLE_ATTRIBUTE_ID        | cn                           |
      | AUTH_LDAP_ROLES_CTX_DN             | ou=Roles,dc=example,dc=com   |
      | AUTH_LDAP_ROLE_FILTER              | (member={1})                 |
      | AUTH_ROLE_MAPPER_ROLES_PROPERTIES  | admin=PowerUser,BillingAdmin |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <mapped-role-mapper name="kie-custom-role-mapper" keep-mapped="false" keep-non-mapped="false">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role-mapping from="admin" to="PowerUser BillingAdmin"/>

  Scenario: Test custom role mapper with mapper keep mapped
    When container is started with env
      | variable                          | value                        |
      | AUTH_LDAP_URL                     | test_url                     |
      | AUTH_LDAP_BIND_DN                 | cn=Manager,dc=example,dc=com |
      | AUTH_LDAP_BIND_CREDENTIAL         | admin                        |
      | AUTH_LDAP_BASE_CTX_DN             | ou=Users,dc=example,dc=com   |
      | AUTH_LDAP_BASE_FILTER             | uid                          |
      | AUTH_LDAP_ROLE_ATTRIBUTE_ID       | cn                           |
      | AUTH_LDAP_ROLES_CTX_DN            | ou=Roles,dc=example,dc=com   |
      | AUTH_LDAP_ROLE_FILTER             | (member={1})                 |
      | AUTH_ROLE_MAPPER_ROLES_PROPERTIES | admin=PowerUser,BillingAdmin |
      | AUTH_LDAP_MAPPER_KEEP_MAPPED      | true                         |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <mapped-role-mapper name="kie-custom-role-mapper" keep-mapped="true" keep-non-mapped="false">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role-mapping from="admin" to="PowerUser BillingAdmin"/>

  Scenario: Test custom role mapper with mapper keep mapped false and non mapped
    When container is started with env
      | variable                          | value                        |
      | AUTH_LDAP_URL                     | test_url                     |
      | AUTH_LDAP_BIND_DN                 | cn=Manager,dc=example,dc=com |
      | AUTH_LDAP_BIND_CREDENTIAL         | admin                        |
      | AUTH_LDAP_BASE_CTX_DN             | ou=Users,dc=example,dc=com   |
      | AUTH_LDAP_BASE_FILTER             | uid                          |
      | AUTH_LDAP_ROLE_ATTRIBUTE_ID       | cn                           |
      | AUTH_LDAP_ROLES_CTX_DN            | ou=Roles,dc=example,dc=com   |
      | AUTH_LDAP_ROLE_FILTER             | (member={1})                 |
      | AUTH_ROLE_MAPPER_ROLES_PROPERTIES | admin=PowerUser,BillingAdmin |
      | AUTH_LDAP_MAPPER_KEEP_MAPPED      | false                        |
      | AUTH_LDAP_MAPPER_KEEP_NON_MAPPED  | true                         |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <mapped-role-mapper name="kie-custom-role-mapper" keep-mapped="false" keep-non-mapped="true">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <role-mapping from="admin" to="PowerUser BillingAdmin"/>

  # https://issues.jboss.org/browse/CLOUD-1145 - base test
  Scenario: Check custom war file was successfully deployed via CUSTOM_INSTALL_DIRECTORIES
    Given s2i build https://github.com/jboss-openshift/openshift-examples.git from custom-install-directories
      | variable                   | value    |
      | CUSTOM_INSTALL_DIRECTORIES | custom   |
    Then file /opt/eap/standalone/deployments/node-info.war should exist

  # RHPAM-2274: S2I build failure when assembly plugin is used
  Scenario: Deploy a jar and its pom files using assembly script.
    Given s2i build https://github.com/jboss-container-images/jboss-kie-modules.git from jboss-kie-kieserver/tests/bats/resources/assembly-build using main
     Then file /home/jboss/.m2/repository/org/kie/kieserver/assembly-build-rhpam-2274/1.0.0/assembly-build-rhpam-2274-1.0.0.jar should exist
      And file /home/jboss/.m2/repository/org/kie/kieserver/assembly-build-rhpam-2274/1.0.0/assembly-build-rhpam-2274-1.0.0.pom should exist
      And file /home/jboss/.m2/repository/org/kie/kie-internal/7.14.0.Final-redhat-00004/kie-internal-7.14.0.Final-redhat-00004.pom should exist
      And file /home/jboss/.m2/repository/org/kie/kie-api/7.14.0.Final-redhat-00004/kie-api-7.14.0.Final-redhat-00004.pom should exist
      And file /home/jboss/.m2/repository/org/kie/soup/kie-soup-maven-support/7.14.0.Final-redhat-00004/kie-soup-maven-support-7.14.0.Final-redhat-00004.pom should exist
      And file /home/jboss/.m2/repository/org/slf4j/slf4j-api/1.7.25/slf4j-api-1.7.25.pom should exist

  Scenario: Verify the KIE_SERVER_BYPASS_AUTH_USER configuration
    When container is started with env
      | variable                    | value    |
      | KIE_SERVER_BYPASS_AUTH_USER | true     |
    Then container log should contain -Dorg.kie.server.bypass.auth.user=true

  Scenario: Verify the KIE_SERVER_CONTROLLER_TOKEN configuration
    When container is started with env
      | variable                    | value    |
      | KIE_SERVER_CONTROLLER_HOST  | myhost   |
      | KIE_SERVER_CONTROLLER_TOKEN | mytoken  |
    Then container log should contain -Dorg.kie.server.controller.token=mytoken

  Scenario: Verify the KIE_SERVER_DOMAIN default configuration
    When container is ready
    Then container log should contain -Dorg.kie.server.domain=other

  Scenario: Verify the KIE_SERVER_DOMAIN configuration
    When container is started with env
      | variable          | value    |
      | KIE_SERVER_DOMAIN | mydomain  |
    Then container log should contain -Dorg.kie.server.domain=mydomain

  Scenario: Verify the KIE_SERVER_TOKEN configuration
    When container is started with env
      | variable         | value             |
      | KIE_SERVER_TOKEN | mykieservertoken  |
    Then container log should contain -Dorg.kie.server.token=mykieservertoken

  Scenario: test DROOLS_SERVER_FILTER_CLASSES configuration
    When container is started with env
      | variable                     | value |
      | DROOLS_SERVER_FILTER_CLASSES | false |
    Then container log should contain -Dorg.drools.server.filter.classes=false

  Scenario: test DROOLS_SERVER_FILTER_CLASSES default configuration
    When container is ready
    Then container log should contain -Dorg.drools.server.filter.classes=true

  Scenario: CLOUD-747/KIECLOUD-49, test multi-module builds
    Given s2i build https://github.com/jboss-container-images/rhpam-7-openshift-image from quickstarts/hello-rules-multi-module using main
      | variable                          | value                                                                         |
      | KIE_SERVER_CONTAINER_DEPLOYMENT   | hellorules=org.openshift.quickstarts:rhpam-kieserver-decisions:1.6.0-SNAPSHOT |
      | ARTIFACT_DIR                      | hellorules/target,hellorules-model/target                                     |
    Then run sh -c 'test -d /home/jboss/.m2/repository/org/openshift/quickstarts/rhpam-kieserver-parent/ && echo all good' in container and check its output for all good
     And run sh -c 'test -f /home/jboss/.m2/repository/org/openshift/quickstarts/rhpam-kieserver-decisions/1.6.0-SNAPSHOT/rhpam-kieserver-decisions-1.6.0-SNAPSHOT.jar && echo all good' in container and check its output for all good
     And run sh -c 'test -f /home/jboss/.m2/repository/org/openshift/quickstarts/rhpam-kieserver-decisions-model/1.6.0-SNAPSHOT/rhpam-kieserver-decisions-model-1.6.0-SNAPSHOT.jar && echo all good' in container and check its output for all good

  Scenario: test Kie Server controller access with default values
    When container is started with env
      | variable                        | value           |
      | KIE_SERVER_CONTROLLER_SERVICE   | MY_COOL_SERVICE |
      | MY_COOL_SERVICE_SERVICE_HOST    | 10.10.10.10     |
    Then container log should contain -Dorg.kie.server.controller=http://10.10.10.10:8080/rest/controller

  Scenario: test Kie Server controller service configuration with default protocol and with port 9191
    When container is started with env
      | variable                        | value       |
      | KIE_SERVER_CONTROLLER_SERVICE   | SERVICE_ONE |
      | SERVICE_ONE_SERVICE_HOST        | localhost   |
      | SERVICE_ONE_SERVICE_PORT        | 9191        |
    Then container log should contain -Dorg.kie.server.controller=http://localhost:9191/rest/controller

  Scenario: test Kie Server controller service configuration with custom host, port and protocol
    When container is started with env
      | variable                       | value        |
      | KIE_SERVER_CONTROLLER_HOST     | my-cool-host |
      | KIE_SERVER_CONTROLLER_PORT     | 443          |
      | KIE_SERVER_CONTROLLER_PROTOCOL | https        |
    Then container log should contain -Dorg.kie.server.controller=https://my-cool-host:443/rest/controller

  Scenario: test Kie Server controller service configuration with https protocol and default port
    When container is started with env
      | variable                       | value        |
      | KIE_SERVER_CONTROLLER_SERVICE  | SERVICE_ONE  |
      | SERVICE_ONE_SERVICE_HOST       | localhost    |
      | KIE_SERVER_CONTROLLER_PROTOCOL | https        |
    Then container log should contain -Dorg.kie.server.controller=https://localhost:8443/rest/controller

  Scenario: test Kie Server controller service configuration with with ws protocol
    When container is started with env
      | variable                       | value        |
      | KIE_SERVER_CONTROLLER_SERVICE  | SERVICE_ONE  |
      | SERVICE_ONE_SERVICE_HOST       | localhost    |
      | KIE_SERVER_CONTROLLER_PROTOCOL | ws           |
    Then container log should contain -Dorg.kie.server.controller=ws://localhost:8080/websocket/controller

  Scenario: test Kie Server controller service configuration with wss protocol and default port
    When container is started with env
      | variable                       | value        |
      | KIE_SERVER_CONTROLLER_SERVICE  | SERVICE_ONE  |
      | SERVICE_ONE_SERVICE_HOST       | 10.10.10.10  |
      | KIE_SERVER_CONTROLLER_PROTOCOL | wss          |
    Then container log should contain -Dorg.kie.server.controller=wss://10.10.10.10:8443/websocket/controller

  Scenario: test Kie Server controller service configuration with wss protocol and custom port
    When container is started with env
      | variable                       | value        |
      | KIE_SERVER_CONTROLLER_SERVICE  | SERVICE_ONE  |
      | SERVICE_ONE_SERVICE_HOST       | localhost    |
      | KIE_SERVER_CONTROLLER_PORT     | 443          |
      | KIE_SERVER_CONTROLLER_PROTOCOL | wss          |
    Then container log should contain -Dorg.kie.server.controller=wss://localhost:443/websocket/controller

  Scenario: test Kie Server controller service configuration wss protocol, custom host and port
    When container is started with env
      | variable                       | value        |
      | KIE_SERVER_CONTROLLER_HOST     | localhost    |
      | KIE_SERVER_CONTROLLER_PORT     | 9443         |
      | KIE_SERVER_CONTROLLER_PROTOCOL | wss          |
    Then container log should contain -Dorg.kie.server.controller=wss://localhost:9443/websocket/controller

  Scenario: test Kie Server router configuration
    When container is started with env
      | variable                        | value       |
      | KIE_SERVER_ROUTER_HOST          | localhost   |
      | KIE_SERVER_ROUTER_PORT          | 9000        |
      | KIE_SERVER_ROUTER_PROTOCOL      | https       |
    Then container log should contain -Dorg.kie.server.router=https://localhost:9000

  Scenario: test Kie Server router service configuration
    When container is started with env
      | variable                        | value       |
      | KIE_SERVER_ROUTER_SERVICE       | SERVICE_ONE |
      | SERVICE_ONE_SERVICE_HOST        | localhost2  |
      | SERVICE_ONE_SERVICE_PORT        | 9001        |
    Then container log should contain -Dorg.kie.server.router=http://localhost2:9001

  Scenario: test Kie Server Sync deploy configuration
    When container is started with env
      | variable                | value  |
      | KIE_SERVER_SYNC_DEPLOY  | true   |
    Then container log should contain -Dorg.kie.server.sync.deploy=true

  Scenario: test Kie Server KIE_SERVER_CONTAINER_DEPLOYMENT_OVERRIDE env
    When container is started with env
      | variable                                  | value                                   |
      | KIE_SERVER_CONTAINER_DEPLOYMENT           | deployment=a.b.c:1.0-SNAPSHOT           |
      | KIE_SERVER_CONTAINER_DEPLOYMENT_OVERRIDE  | deploymentOverride=a.b.c:1.0-SNAPSHOT   |
    Then container log should contain Encountered EnvVar KIE_SERVER_CONTAINER_DEPLOYMENT_OVERRIDE: deploymentOverride=a.b.c:1.0-SNAPSHOT
    And container log should contain Setting EnvVar KIE_SERVER_CONTAINER_DEPLOYMENT_ORIGINAL: deployment=a.b.c:1.0-SNAPSHOT
    And container log should contain Using overridden EnvVar KIE_SERVER_CONTAINER_DEPLOYMENT: deploymentOverride=a.b.c:1.0-SNAPSHOT
    And container log should contain KIE_SERVER_CONTAINER_DEPLOYMENT: deploymentOverride=a.b.c:1.0-SNAPSHOT
    And container log should contain KIE_SERVER_CONTAINER_DEPLOYMENT_ORIGINAL: deployment=a.b.c:1.0-SNAPSHOT
    And container log should contain KIE_SERVER_CONTAINER_DEPLOYMENT_OVERRIDE: deploymentOverride=a.b.c:1.0-SNAPSHOT
    And container log should contain KIE_SERVER_CONTAINER_DEPLOYMENT_COUNT: 1
    And container log should contain KIE_SERVER_CONTAINER_ID_0: deploymentOverride
    And container log should contain KIE_SERVER_CONTAINER_KJAR_GROUP_ID_0: a.b.c
    And container log should contain KIE_SERVER_CONTAINER_KJAR_ARTIFACT_ID_0: 1.0-SNAPSHOT

  Scenario: Check that mode property gets set for development.
    When container is started with env
      | variable        | value       |
      | KIE_SERVER_MODE | DEVELOPMENT |
    Then container log should contain -Dorg.kie.server.mode=DEVELOPMENT

  Scenario: Check that mode property gets set for production.
    When container is started with env
      | variable        | value      |
      | KIE_SERVER_MODE | PRODUCTION |
    Then container log should contain -Dorg.kie.server.mode=PRODUCTION

  Scenario: Check that mode property is not set without env.
    When container is started with env
      | variable        | value  |
    Then container log should not contain -Dorg.kie.server.mode=

  Scenario: Check that mode property complains given illegal value.
    When container is started with env
      | variable        | value  |
      | KIE_SERVER_MODE | foobar |
    Then container log should contain Invalid value "foobar" for KIE_SERVER_MODE. Must be "DEVELOPMENT" or "PRODUCTION".

  Scenario: Check that prometheus properties are enabled.
    When container is started with env
      | variable                       | value |
      | PROMETHEUS_SERVER_EXT_DISABLED | false |
      | AB_PROMETHEUS_ENABLE           | true  |
    Then container log should contain -Dorg.kie.prometheus.server.ext.disabled=false
     And container log should contain -javaagent:/opt/jboss/container/prometheus/jmx_prometheus_javaagent.jar=9799:/opt/jboss/container/prometheus/etc/jmx-exporter-config.yaml

  Scenario: Check that prometheus properties are disabled.
    When container is started with env
      | variable                       | value |
      | PROMETHEUS_SERVER_EXT_DISABLED | true  |
      | AB_PROMETHEUS_ENABLE           | false |
    Then container log should contain -Dorg.kie.prometheus.server.ext.disabled=true
     And container log should not contain -javaagent:/opt/jboss/container/prometheus/jmx_prometheus_javaagent.jar

  Scenario: Check bad prometheus env and no AB env.
    When container is started with env
      | variable                       | value  |
      | PROMETHEUS_SERVER_EXT_DISABLED | foobar |
    Then container log should contain Invalid value "foobar" for PROMETHEUS_SERVER_EXT_DISABLED. Must be "true" or "false".
     And container log should not contain -javaagent:/opt/jboss/container/prometheus/jmx_prometheus_javaagent.jar

  Scenario: KIECLOUD-122 - Enable JMS for IBM BAMOE, remove unneeded files
    When container is ready
    Then file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/weblogic-ejb-jar.xml should not exist

  Scenario: KIECLOUD-122 - Enable JMS for IBM BAMOE, check if the custom jms file configuration are present on the image
    When container is ready
    Then file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/ejb-jar.xml should contain org.kie.server.jms.KieServerMDB
     And file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/ejb-jar.xml should contain org.kie.server.jms.executor.KieExecutorMDB

  Scenario: KIECLOUD-122 - Enable JMS for IBM BAMOE, test default request/response queue values on kie-server-jms.xml
    When container is ready
    Then file /opt/eap/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml should contain <entry name="queue/KIE.SERVER.REQUEST" />
     And file /opt/eap/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml should contain <jms-queue name="KIE.SERVER.REQUEST">
     And file /opt/eap/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml should contain <entry name="java:jboss/exported/jms/queue/KIE.SERVER.REQUEST" />
     And file /opt/eap/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml should contain <entry name="queue/KIE.SERVER.RESPONSE" />
     And file /opt/eap/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml should contain <jms-queue name="KIE.SERVER.RESPONSE">
     And file /opt/eap/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml should contain <entry name="java:jboss/exported/jms/queue/KIE.SERVER.RESPONSE" />
     And file /opt/eap/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml should contain <entry name="queue/KIE.SERVER.EXECUTOR" />
     And file /opt/eap/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml should contain <jms-queue name="KIE.SERVER.EXECUTOR">
     And file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/ejb-jar.xml should contain <activation-config-property-value>queue/KIE.SERVER.REQUEST</activation-config-property-value>
     And file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/ejb-jar.xml should contain <activation-config-property-value>queue/KIE.SERVER.EXECUTOR</activation-config-property-value>

  Scenario: KIECLOUD-122 - Enable JMS for IBM BAMOE, test custom request/response queue values on kie-server-jms.xml
    When container is started with env
      | variable                       | value                        |
      | KIE_SERVER_JMS_QUEUE_RESPONSE  | queue/MY.KIE.SERVER.RESPONSE |
      | KIE_SERVER_JMS_QUEUE_REQUEST   | queue/MY.KIE.SERVER.REQUEST  |
      | KIE_SERVER_JMS_QUEUE_EXECUTOR  | queue/MY.KIE.SERVER.EXECUTOR |
    Then file /opt/eap/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml should contain <entry name="queue/MY.KIE.SERVER.REQUEST" />
     And file /opt/eap/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml should contain <entry name="java:jboss/exported/jms/queue/MY.KIE.SERVER.REQUEST" />
     And file /opt/eap/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml should contain <entry name="queue/MY.KIE.SERVER.RESPONSE" />
     And file /opt/eap/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml should contain <entry name="java:jboss/exported/jms/queue/MY.KIE.SERVER.RESPONSE" />
     And file /opt/eap/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml should contain <entry name="queue/MY.KIE.SERVER.EXECUTOR" />
     And file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/ejb-jar.xml should contain <activation-config-property-value>queue/MY.KIE.SERVER.REQUEST</activation-config-property-value>
     And file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/ejb-jar.xml should contain <activation-config-property-value>queue/MY.KIE.SERVER.EXECUTOR</activation-config-property-value>

  Scenario: KIECLOUD-122 - Enable JMS for IBM BAMOE, verify if the JMS is disabled
    When container is started with env
      | variable                | value    |
      | KIE_SERVER_EXECUTOR_JMS | false    |
    Then container log should not contain -Dorg.kie.executor.jms=true
     And container log should contain -Dorg.kie.executor.jms=false
     And container log should not contain Executor JMS based support successfully activated on queue ActiveMQQueue[jms.queue.KIE.SERVER.EXECUTOR]
     And container log should not contain -Dorg.kie.executor.jms.transacted
     And container log should not contain -Dorg.kie.executor.jms.queue

  Scenario: KIECLOUD-122 - Enable JMS for IBM BAMOE, verify META-INF/jms-server-jms.xml is removed if external AMQ integration is enabled
    When container is started with env
      | variable                  | value     |
      | MQ_SERVICE_PREFIX_MAPPING | AMQPREFIX |
    Then container log should contain Configuring external JMS integration, removing /opt/eap/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml
     And file /opt/eap/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml should not exist

  Scenario: RHDM-1096 - Check that optaplanner thread pool queue size property is not set without env.
    When container is started with env
      | variable        | value  |
    Then container log should not contain -Dorg.optaplanner.server.ext.thread.pool.queue.size=

  Scenario: RHDM-1096 - Check that optaplanner thread pool queue size property is set
    When container is started with env
      | variable                                      | value |
      | OPTAPLANNER_SERVER_EXT_THREAD_POOL_QUEUE_SIZE | 4     |
    Then container log should contain -Dorg.optaplanner.server.ext.thread.pool.queue.size=4

  Scenario: test MAVEN_MIRROR_URL configuration
    When container is started with env
      | variable         | value                                     |
      | MAVEN_MIRROR_URL | http://nexus-test.127.0.0.1.nip.ip/nexus/ |
    Then file /home/jboss/.m2/settings.xml should contain <id>mirror.default</id>
    And file /home/jboss/.m2/settings.xml should contain <url>http://nexus-test.127.0.0.1.nip.ip/nexus/</url>
    And file /home/jboss/.m2/settings.xml should contain <mirrorOf>external:*</mirrorOf>

  Scenario: RHPAM-3517: Update maven to 3.6
    When container is started with command bash
    Then run sh -c "mvn --version | sed -n -e 's/^.*Apache //p' | grep 3.6 && echo  all good" in container and check its output for all good

  Scenario: Check if the GC_MAX_METASPACE_SIZE is set to 512 if KIE_SERVER_MAX_METASPACE_SIZE is not set
    When container is ready
    Then container log should contain -XX:MaxMetaspaceSize=512m

  Scenario: Check if the KIE_SERVER_MAX_METASPACE_SIZE is correctly set
    When container is started with env
      | variable                       | value   |
      | KIE_SERVER_MAX_METASPACE_SIZE  | 2048    |
    Then container log should contain -XX:MaxMetaspaceSize=2048m

  Scenario: Check if the GC_MAX_METASPACE_SIZE is correctly set and bypass KIE_SERVER_MAX_METASPACE_SIZE env
    When container is started with env
      | variable                | value   |
      | GC_MAX_METASPACE_SIZE   | 4096    |
    Then container log should contain -XX:MaxMetaspaceSize=4096m

  Scenario: Check if the WORKBENCH_MAX_METASPACE_SIZE takes precedence when KIE_SERVER_MAX_METASPACE_SIZE and GC_MAX_METASPACE_SIZE are set
    When container is started with env
      | variable                       | value   |
      | KIE_SERVER_MAX_METASPACE_SIZE  | 4096    |
      | GC_MAX_METASPACE_SIZE          | 2048    |
    Then container log should contain -XX:MaxMetaspaceSize=4096m

  Scenario: Verify if the warning message is correctly printed if there is no KIE_SERVER_CONTAINER_DEPLOYMENT set
    When container is started with env
      | variable                       | value   |
      | GC_MAX_METASPACE_SIZE          | 2048    |
    Then container log should contain Warning: EnvVar KIE_SERVER_CONTAINER_DEPLOYMENT is missing.
     And container log should contain Example: export KIE_SERVER_CONTAINER_DEPLOYMENT='containerId(containerAlias)=groupId:artifactId:version|c2(n2)=g2:a2:v2'

  Scenario: Verify if the KJar verification is is correctly disabled
    When container is started with env
      | variable                            | value                          |
      | KIE_SERVER_CONTAINER_DEPLOYMENT     | test=org.package:mypackage:1.0 |
      # PULLS are disabled intentionally here otherwise container will fail before reach the container verification to start because the provided package is not valid.
      | KIE_SERVER_DISABLE_KC_PULL_DEPS     | true                           |
      | KIE_SERVER_DISABLE_KC_VERIFICATION  | true                           |
    Then container log should contain Using standard EnvVar KIE_SERVER_CONTAINER_DEPLOYMENT: test=org.package:mypackage:1.0
     And container log should contain WARN KIE Jar verification disabled, skipping. Please make sure that the provided KJar was properly tested before deploying it.

  Scenario: Scenario: Verify if the pull dependencies is correctly disabled and KJar verification is correctly triggered
    When container is started with env
      | variable                            | value                          |
      | KIE_SERVER_CONTAINER_DEPLOYMENT     | test=org.package:mypackage:1.0 |
      | KIE_SERVER_DISABLE_KC_PULL_DEPS     | true                           |
    Then container log should contain Using standard EnvVar KIE_SERVER_CONTAINER_DEPLOYMENT: test=org.package:mypackage:1.0
     And container log should contain WARN Pull dependencies is disabled, skipping. Please make sure to provide all dependencies needed by the specified kjar.
     And container log should contain INFO Attempting to verify kie server containers with 'java org.kie.server.services.impl.KieServerContainerVerifier  org.package:mypackage:1.0'

  Scenario: Verify if the pull dependencies is correctly triggered
    When container is started with env
      | variable                            | value                          |
      | KIE_SERVER_CONTAINER_DEPLOYMENT     | test=org.package:mypackage:1.0 |
    Then container log should contain Using standard EnvVar KIE_SERVER_CONTAINER_DEPLOYMENT: test=org.package:mypackage:1.0
     And container log should contain INFO Attempting to pull dependencies for kjar 0 with

  Scenario: Verify if the KieExecutorMDB is configured
    When container is started with env
      | variable                            | value                          |
      | KIE_EXECUTOR_MDB_MAX_SESSIONS       | 987654321123456789                  |
      | JAVA_OPTS_APPEND                    | -Djboss.mdb.strict.max.pool.size=40 |
      Then container log should contain Configuring KieServerExecutorMDB Max Sessions on ejb-jar.xml
       And file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/ejb-jar.xml should contain <ejb-class>org.kie.server.jms.executor.KieExecutorMDB</ejb-class>
       And file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/ejb-jar.xml should contain <activation-config-property-name>maxSession</activation-config-property-name>
       And file /opt/eap/standalone/deployments/ROOT.war/WEB-INF/ejb-jar.xml should contain <activation-config-property-value>987654321123456789</activation-config-property-value>
       And container log should contain -Djboss.mdb.strict.max.pool.size=40
       And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <strict-max-pool name="mdb-strict-max-pool" derive-size="from-cpu-count"

  Scenario: Verify if the ACCESS_LOG_VALVE is configured
    When container is started with env
      | variable                             | value                         |
      | ENABLE_ACCESS_LOG                    | true                          |
    Then container log should contain Configuring Access Log Valve
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain ##ACCESS_LOG_VALVE##
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain access-log use-server-log="true"
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain pattern="%h %l %u %t %{i,X-Forwarded-Host} &quot;%r&quot; %s %b"

  Scenario: Verify if the ACCESS_LOG_VALVE is not configured
     When container is started with env
       | variable                             | value                         |
     Then container log should contain Access log is disabled, ignoring configuration.

  Scenario: Verify that KieServer has got decision only capabilities

  Scenario: Verify if the KieExecutorMDB is configured
    When container is started with env
      | variable                             | value                         |
      | KIE_SERVER_DECISIONS_ONLY             | TRUE                          |
    Then container log should contain KIE Server will be executed with DM only capabilities.
     And container log should contain KIE Server's cluster for Jbpm failover is disabled.
     And container log should contain Drools KIE Server extension has been successfully registered as server extension
     And container log should contain DMN KIE Server extension has been successfully registered as server extension
     And container log should contain OptaPlanner KIE Server extension has been successfully registered as server extension
     And container log should not contain jBPM KIE Server extension has been successfully registered as server extension
     And container log should not contain Case-Mgmt KIE Server extension has been successfully registered as server extension
     And container log should not contain jBPM-UI KIE Server extension has been successfully registered as server extension
     And container log should not contain Kafka JBPM Emitter enabled
     And container log should not contain EJB Timer will be auto configured if any datasource is configured via DB_SERVICE_PREFIX_MAPPING or DATASOURCES envs.

  Scenario: Verify that KieServer is started with all the capabilities/extensions by default
    When container is started with env
      | variable                             | value                         |
    Then container log should contain KIE Server's cluster for Jbpm failover is disabled.
    And container log should contain Drools KIE Server extension has been successfully registered as server extension
    And container log should contain DMN KIE Server extension has been successfully registered as server extension
    And container log should contain OptaPlanner KIE Server extension has been successfully registered as server extension
    And container log should contain jBPM KIE Server extension has been successfully registered as server extension
    And container log should contain Case-Mgmt KIE Server extension has been successfully registered as server extension
    And container log should contain jBPM-UI KIE Server extension has been successfully registered as server extension
