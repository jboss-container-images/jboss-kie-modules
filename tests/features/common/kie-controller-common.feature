@rhdm-7/rhdm-controller-rhel8 @rhpam-7/rhpam-controller-rhel8
Feature: KIE Controller configuration common tests

  Scenario: Test REST API is secure
    When container is ready
    Then check that page is served
      | property             | value               |
      | port                 | 8080                |
      | path                 | /management/servers |
      | expected_status_code | 403                 |

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

  Scenario: Check if eap users are not being created if SSO is configured with no users env
    When container is started with env
      | variable                   | value         |
      | SSO_URL                    | http://url    |
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain adminUser
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain adminUser
     And container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain Make sure to configure KIE_ADMIN_USER user to access the application with the roles kie-server,rest-all,admin,kiemgmt,Administrators,user

  Scenario: Check if eap users are not being created if LDAP is configured with no users env
    When container is started with env
      | variable                   | value         |
      | AUTH_LDAP_URL              | ldap://url:389|
    Then file /opt/eap/standalone/configuration/application-users.properties should not contain adminUser
     And file /opt/eap/standalone/configuration/application-roles.properties should not contain adminUser
     And container log should contain External authentication/authorization enabled, skipping the embedded users creation.
     And container log should contain Make sure to configure KIE_ADMIN_USER user to access the application with the roles kie-server,rest-all,admin,kiemgmt,Administrators,user

  Scenario: RHPAM-3517: Update maven to 3.6
    When container is started with command bash
    Then run sh -c "mvn --version | sed -n -e 's/^.*Apache //p' | grep 3.6 && echo  all good" in container and check its output for all good

  Scenario: Verify if the HTTPS is not configured
     When container is started with env
       | variable                             | value                         |
     Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain ##SSL##
      And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain ##HTTPS_CONNECTOR##

  Scenario: Verify if the HTTPS is configured for ELYTRON
     When container is started with env
       | variable                             | value                         |
       | CONFIGURE_ELYTRON_SSL                | true                          |
     Then container log should contain Using Elytron for SSL configuration.

  Scenario: Verify if the HTTPS is configured
     When container is started with env
       | variable                             | value                         |
       | HTTPS_PASSWORD                       | 0p3n$3s@m3                    |
       | HTTPS_KEYSTORE_DIR                   | /opt/eap/keys                 |
       | HTTPS_KEYSTORE                       | keystore                      |
       | HTTPS_KEYSTORE_TYPE                  | idk                           |
     Then file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain ##SSL##
      And file /opt/eap/standalone/configuration/standalone-openshift.xml should not contain ##HTTPS_CONNECTOR##
      And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <https-listener name="https" socket-binding="https" security-realm="ApplicationRealm" proxy-address-forwarding="true"/>

