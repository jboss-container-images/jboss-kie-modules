@rhdm-7/rhdm71-kieserver-openshift  @rhpam-7/rhpam71-kieserver-openshift
Feature: Kie Server common features

  Scenario: Check if kieserver mgmt is correctly set.
    When container is started with env
      | variable                   | value  |
      | KIE_SERVER_MGMT_DISABLED   | true   |
    Then container log should contain -Dorg.kie.server.mgmt.api.disabled=true

  Scenario: Configure kie server to be immutable, disable management and set startup strategy
    When container is started with env
      | variable                    | value                          |
      | KIE_SERVER_MGMT_DISABLED    | true                           |
      | KIE_SERVER_STARTUP_STRATEGY | LocalContainersStartupStrategy |
    Then container log should contain -Dorg.kie.server.mgmt.api.disabled=true
     And container log should contain -Dorg.kie.server.startup.strategy=LocalContainersStartupStrategy

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
