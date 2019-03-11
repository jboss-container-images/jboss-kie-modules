@rhdm-7/rhdm73-kieserver-openshift  @rhpam-7/rhpam73-kieserver-openshift
Feature: Kie Server common features

  Scenario: Check if kieserver mgmt is correctly set.
    When container is started with env
      | variable                   | value  |
      | KIE_SERVER_MGMT_DISABLED   | true   |
    Then container log should contain -Dorg.kie.server.mgmt.api.disabled=true

  Scenario: Test REST API is available and valid
    When container is started with env
      | variable         | value       |
      | KIE_SERVER_USER  | kieserver   |
      | KIE_SERVER_PWD   | kieserver1! |
    Then check that page is served
      | property        | value                 |
      | port            | 8080                  |
      | path            | /services/rest/server |
      | wait            | 80                    |
      | username        | kieserver             |
      | password        | kieserver1!           |
      | expected_phrase | SUCCESS               |

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

  # https://issues.jboss.org/browse/RHPAM-891
  # https://issues.jboss.org/browse/RHPAM-1135
  Scenario: Check custom users are properly configured
    When container is started with env
      | variable                   | value         |
      | KIE_ADMIN_USER             | customAdm     |
      | KIE_ADMIN_PWD              | custom" Adm!0 |
      | KIE_MAVEN_USER             | customMvn     |
      | KIE_MAVEN_PWD              | custom" Mvn!0 |
      | KIE_SERVER_CONTROLLER_USER | customCtl     |
      | KIE_SERVER_CONTROLLER_PWD  | custom" Ctl!0 |
      | KIE_SERVER_USER            | customExe     |
      | KIE_SERVER_PWD             | custom" Exe!0 |
    Then file /opt/eap/standalone/configuration/application-users.properties should contain customAdm=a4d41e50a4ae17a50c1ceabe21e41a80
     And file /opt/eap/standalone/configuration/application-roles.properties should contain customAdm=kie-server,rest-all,admin,kiemgmt,Administrators
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customMvn
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customMvn
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customCtl
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customCtl
     And file /opt/eap/standalone/configuration/application-users.properties should contain customExe=d2d5d854411231a97fdbf7fe6f91a786
     And file /opt/eap/standalone/configuration/application-roles.properties should contain customExe=kie-server,rest-all,guest

  Scenario: Check if eap users are not being created if SSO is configured
    When container is started with env
      | variable                   | value         |
      | SSO_URL                    | http://url    |
      | KIE_SERVER_CONTROLLER_USER | customCtl     |
      | KIE_SERVER_CONTROLLER_PWD  | custom" Ctl!0 |
      | KIE_SERVER_USER            | customExe     |
      | KIE_SERVER_PWD             | custom" Exe!0 |
      | KIE_ADMIN_USER             | customExe     |
      | KIE_ADMIN_PWD              | custom" Exe!0 |
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain customCtl
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customCtl
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customExe=d2d5d854411231a97fdbf7fe6f91a786
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customExe=kie-server,rest-all,guest
     And container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain KIE_SERVER_USER is set to customExe, make sure to configure this user with the provided password on the external auth provider with the roles kie-server,rest-all,guest
     And container log should contain KIE_SERVER_CONTROLLER_USER is set to customCtl, make sure to configure this user with the provided password on the external auth provider with the roles kie-server,rest-all,guest
     And container log should contain KIE_ADMIN_USER is set to customExe, make sure to configure this user with the provided password on the external auth provider with the roles kie-server,rest-all,admin,kiemgmt,Administrators

  Scenario: Check if eap users are not being created if LDAP is configured
    When container is started with env
      | variable                   | value         |
      | AUTH_LDAP_URL              | ldap://url:389|
      | KIE_SERVER_CONTROLLER_USER | customCtl     |
      | KIE_SERVER_CONTROLLER_PWD  | custom" Ctl!0 |
      | KIE_SERVER_USER            | customExe     |
      | KIE_SERVER_PWD             | custom" Exe!0 |
      | KIE_ADMIN_USER             | customExe     |
      | KIE_ADMIN_PWD              | custom" Exe!0 |
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain customCtl
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customCtl
     And file /opt/eap/standalone/configuration/application-users.properties should not contain customExe=d2d5d854411231a97fdbf7fe6f91a786
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain customExe=kie-server,rest-all,guest
     And container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain KIE_SERVER_USER is set to customExe, make sure to configure this user with the provided password on the external auth provider with the roles kie-server,rest-all,guest
     And container log should contain KIE_SERVER_CONTROLLER_USER is set to customCtl, make sure to configure this user with the provided password on the external auth provider with the roles kie-server,rest-all,guest
     And container log should contain KIE_ADMIN_USER is set to customExe, make sure to configure this user with the provided password on the external auth provider with the roles kie-server,rest-all,admin,kiemgmt,Administrators

  Scenario: Check if eap users are not being created if SSO is configured with no users env
    When container is started with env
      | variable                   | value         |
      | SSO_URL                    | http://url    |
    Then container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain Make sure to configure the KIE_MAVEN_USER user to interact with Business Central embedded maven server
     And container log should contain Make sure to configure the KIE_SERVER_CONTROLLER_USER user to interact with KIE Server rest api with the roles kie-server,rest-all,guest
     And container log should contain Make sure to configure the KIE_SERVER_USER user to interact with KIE Server rest api with the roles kie-server,rest-all,guest
     And container log should contain Make sure to configure a ADMIN user to access the Business Central with the roles kie-server,rest-all,admin,kiemgmt,Administrators

  Scenario: Check if eap users are not being created if LDAP is configured with no users env
    When container is started with env
      | variable                   | value         |
      | AUTH_LDAP_URL              | ldap://url:389|
    Then container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain Make sure to configure the KIE_MAVEN_USER user to interact with Business Central embedded maven server
     And container log should contain Make sure to configure the KIE_SERVER_CONTROLLER_USER user to interact with KIE Server rest api with the roles kie-server,rest-all,guest
     And container log should contain Make sure to configure the KIE_SERVER_USER user to interact with KIE Server rest api with the roles kie-server,rest-all,guest
     And container log should contain Make sure to configure a ADMIN user to access the Business Central with the roles kie-server,rest-all,admin,kiemgmt,Administrators

  Scenario: Check custom users are properly configured
    When container is started with env
      | variable                   | value         |
      | KIE_ADMIN_USER             | customAdm     |
      | KIE_ADMIN_PWD              | custom" Adm!0 |
      | KIE_ADMIN_ROLES            | role1,admin2  |
      | KIE_SERVER_USER            | customExe     |
      | KIE_SERVER_PWD             | custom" Exe!0 |
      | KIE_SERVER_ROLES           | role2         |
    Then file /opt/eap/standalone/configuration/application-users.properties should contain customAdm=a4d41e50a4ae17a50c1ceabe21e41a80
    And file /opt/eap/standalone/configuration/application-roles.properties should contain customAdm=role1,admin2
    And file /opt/eap/standalone/configuration/application-users.properties should contain customExe=d2d5d854411231a97fdbf7fe6f91a786
    And file /opt/eap/standalone/configuration/application-roles.properties should contain customExe=role2

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

  Scenario: Configure kie server to use LDAP authentication
    When container is started with env
      | variable                    | value                         |
      | AUTH_LDAP_URL               | test_url                      |
      | AUTH_LDAP_BIND_DN           | cn=Manager,dc=example,dc=com  |
      | AUTH_LDAP_BIND_CREDENTIAL   | admin                         |
      | AUTH_LDAP_BASE_CTX_DN       | ou=Users,dc=example,dc=com    |
      | AUTH_LDAP_BASE_FILTER       | (uid={0})                     |
      | AUTH_LDAP_ROLE_ATTRIBUTE_ID | cn                            |
      | AUTH_LDAP_ROLES_CTX_DN      | ou=Roles,dc=example,dc=com    |
      | AUTH_LDAP_ROLE_FILTER       | (member={1})                  |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <login-module code="RealmDirect" flag="optional">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <login-module code="LdapExtended" flag="required">
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="java.naming.provider.url" value="test_url"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="bindDN" value="cn=Manager,dc=example,dc=com"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="bindCredential" value="admin"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="baseCtxDN" value="ou=Users,dc=example,dc=com"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="baseFilter" value="(uid={0})"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="rolesCtxDN" value="ou=Roles,dc=example,dc=com"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="roleFilter" value="(member={1})"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="roleAttributeID" value="cn"/>

  Scenario: Don't configure kie server to use LDAP authentication
    When container is ready
    Then container log should contain AUTH_LDAP_URL not set. Skipping LDAP integration...
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain <login-module code="LdapExtended"

  Scenario: Configure kie server to use LDAP authentication
    When container is started with env
      | variable      | value     |
      | AUTH_LDAP_URL | test_url  |
    Then container log should contain AUTH_LDAP_URL is set to test_url. Added LdapExtended login-module
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <login-module code="LdapExtended"

  Scenario: Test custom login module configuration
    When container is started with env
      | variable                          | value              |
      | AUTH_ROLE_MAPPER_ROLES_PROPERTIES | roles_mapper_test  |
      | AUTH_ROLE_MAPPER_REPLACE_ROLE     | role_test          |
    Then container log should contain AUTH_ROLE_MAPPER_ROLES_PROPERTIES is set to roles_mapper_test
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="rolesProperties" value="roles_mapper_test"/>
    And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <module-option name="replaceRole" value="role_test"/>

  # https://issues.jboss.org/browse/CLOUD-1145 - base test
  Scenario: Check custom war file was successfully deployed via CUSTOM_INSTALL_DIRECTORIES
    Given s2i build https://github.com/jboss-openshift/openshift-examples.git from custom-install-directories
      | variable                   | value    |
      | CUSTOM_INSTALL_DIRECTORIES | custom   |
    Then file /opt/eap/standalone/deployments/node-info.war should exist

  Scenario: Verify the KIE_SERVER_BYPASS_AUTH_USER configuration
    When container is started with env
      | variable                    | value    |
      | KIE_SERVER_BYPASS_AUTH_USER | true     |
    Then container log should contain -Dorg.kie.server.bypass.auth.user=true

  Scenario: Verify the KIE_SERVER_CONTROLLER_TOKEN configuration
    When container is started with env
      | variable                    | value    |
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
    Given s2i build https://github.com/jboss-container-images/rhdm-7-openshift-image from quickstarts/hello-rules-multi-module using master
      | variable                          | value                                                                         |
      | KIE_SERVER_CONTAINER_DEPLOYMENT   | hellorules=org.openshift.quickstarts:rhdm-kieserver-hellorules:1.4.0-SNAPSHOT |
      | ARTIFACT_DIR                      | hellorules/target,hellorules-model/target                                     |
    Then run sh -c 'test -d /home/jboss/.m2/repository/org/openshift/quickstarts/rhdm-kieserver-parent/ && echo all good' in container and check its output for all good
    And run sh -c 'test -f /home/jboss/.m2/repository/org/openshift/quickstarts/rhdm-kieserver-hellorules/1.4.0-SNAPSHOT/rhdm-kieserver-hellorules-1.4.0-SNAPSHOT.jar && echo all good' in container and check its output for all good
    And run sh -c 'test -f /home/jboss/.m2/repository/org/openshift/quickstarts/rhdm-kieserver-hellorules/1.4.0-SNAPSHOT/rhdm-kieserver-hellorules-1.4.0-SNAPSHOT-sources.jar && echo all good' in container and check its output for all good
    And run sh -c 'test -f /home/jboss/.m2/repository/org/openshift/quickstarts/rhdm-kieserver-hellorules-model/1.4.0-SNAPSHOT/rhdm-kieserver-hellorules-model-1.4.0-SNAPSHOT.jar && echo all good' in container and check its output for all good
    And run sh -c 'test -f /home/jboss/.m2/repository/org/openshift/quickstarts/rhdm-kieserver-hellorules-model/1.4.0-SNAPSHOT/rhdm-kieserver-hellorules-model-1.4.0-SNAPSHOT-sources.jar && echo all good' in container and check its output for all good

  Scenario: test Kie Server controller configuration
    When container is started with env
      | variable                        | value     |
      | KIE_SERVER_CONTROLLER_HOST      | localhost |
      | KIE_SERVER_CONTROLLER_PORT      | 8080      |
      | KIE_SERVER_CONTROLLER_PROTOCOL  | ws        |
    Then container log should contain -Dorg.kie.server.controller=ws://localhost:8080/websocket/controller

  Scenario: test Kie Server controller service configuration
    When container is started with env
      | variable                        | value       |
      | KIE_SERVER_CONTROLLER_SERVICE   | SERVICE_ONE |
      | SERVICE_ONE_SERVICE_HOST        | localhost   |
      | SERVICE_ONE_SERVICE_PORT        | 8080        |
    Then container log should contain -Dorg.kie.server.controller=http://localhost:8080/rest/controller

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
