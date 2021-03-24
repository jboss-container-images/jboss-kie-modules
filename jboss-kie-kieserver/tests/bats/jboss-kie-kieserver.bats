#!/usr/bin/env bats

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
mkdir -p $JBOSS_HOME/bin/launch
mkdir -p $JBOSS_HOME/standalone/configuration

cp $BATS_TEST_DIRNAME/../../../tests/bats/common/launch-common.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../tests/bats/common/logging.bash $JBOSS_HOME/bin/launch/logging.sh
cp $BATS_TEST_DIRNAME/../../../jboss-kie-common/added/launch/jboss-kie-common.sh $JBOSS_HOME/bin/launch/jboss-kie-common.sh
cp $BATS_TEST_DIRNAME/../../../jboss-kie-wildfly-common/added/launch/jboss-kie-wildfly-security-login-modules.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../jboss-kie-wildfly-common/added/launch/jboss-kie-wildfly-common.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../jboss-kie-wildfly-common/added/launch/jboss-kie-wildfly-security.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../jboss-eap-config-openshift/EAP7.3.0/added/standalone-openshift.xml $JBOSS_HOME/standalone/configuration/standalone-openshift.xml

# mocking
touch $JBOSS_HOME/bin/launch/datasource-common.sh

#imports
source $BATS_TEST_DIRNAME/../../added/launch/jboss-kie-kieserver.sh

teardown() {
    rm -rf $JBOSS_HOME
}

@test "test if the EJB_TIMER datasource has been auto-configured" {
  local expected_timer_service="EJB_TIMER"
  local expected_datasources="EJB_TIMER,RHPAM"
  local expected_url="jdbc:h2:/deployments/data/h2/rhpam;AUTO_SERVER=TRUE"
  export DATASOURCES="RHPAM"
  export RHPAM_XA_CONNECTION_PROPERTY_URL="${expected_url}"
  export RHPAM_NONXA="false"
  configure_EJB_Timer_datasource >&2
  echo "Expected EJB_TIMER url is ${EJB_TIMER_XA_CONNECTION_PROPERTY_URL}" >&2
  echo "Expected RHPAM_URL is ${RHPAM_URL}" >&2
  echo "Expected DATASOURCES is ${DATASOURCES}" >&2
  [ "${TIMER_SERVICE_DATA_STORE^^}" = "${expected_timer_service}" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_URL}" = "${expected_url}" ]
  [ "${RHPAM_XA_CONNECTION_PROPERTY_URL}" = "${expected_url}" ]
  [ "${DATASOURCES}" = "${expected_datasources}" ]
  [ "${RHPAM_NONXA}" = "false" ]
  [ "${RHPAM_XA_CONNECTION_PROPERTY_URL}" = "${RHPAM_URL}" ]
}

@test "verify if EJB_TIMER is correctly configured with data-sources when driver is mariadb" {
  local expected_timer_service="EJB_TIMER"
  local expected_datasources="EJB_TIMER,RHPAM"
  export DATASOURCES="RHPAM"
  export RHPAM_DRIVER="mariadb"
  export RHPAM_DATABASE="rhpam-mariadb"
  export RHPAM_USERNAME="rhpam-user$0"
  export RHPAM_PASSWORD="rhpam-pwd$0"
  export RHPAM_SERVICE_HOST="myapp-host"
  export RHPAM_SERVICE_PORT="3306"
  export RHPAM_JNDI="jboss:/datasources/rhpam"
  export RHPAM_JTA="true"
  configure_EJB_Timer_datasource >&2
  echo "EJBTimer url is ${EJB_TIMER_XA_CONNECTION_PROPERTY_Url} " >&2
  [ "${TIMER_SERVICE_DATA_STORE^^}" = "${expected_timer_service}" ]
  [ "${DATASOURCES}" = "${expected_datasources}" ]
  [ "${EJB_TIMER_DRIVER}" = "${RHPAM_DRIVER}" ]
  [ "${EJB_TIMER_PASSWORD}" = "rhpam-pwd$0" ]
  [ "${EJB_TIMER_USERNAME}" = "rhpam-user$0" ]
  [ "${RHPAM_URL}" = "jdbc:mariadb://myapp-host:3306/rhpam-mariadb?enabledSslProtocolSuites=TLSv1.2" ]
  # we do not expect that this var is set anymore, since we're using URL property directly
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_PinGlobalTxToPhysicalConnection}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_EnabledSslProtocolSuites}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_ServerName}" = "${RHPAM_SERVICE_HOST}" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_DatabaseName}" = "${RHPAM_DATABASE}" ]
  # the URL property must be set
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_Url}" = "jdbc:mariadb://myapp-host:3306/rhpam-mariadb?pinGlobalTxToPhysicalConnection=true\&amp;enabledSslProtocolSuites=TLSv1.2" ]
}

@test "verify if EJB_TIMER related default settings are set" {
  local TIMER_SERVICE_DATA_STORE="EJB_TIMER"
  local expected_ejb_timer_tx="-Dorg.jbpm.ejb.timer.tx=true"
  local expected_ejb_timer_local_cache="-Dorg.jbpm.ejb.timer.local.cache=false"
  configure_EJB_Timer_datasource >&2
  echo "Result is ${JBOSS_KIE_ARGS}"
  [[ $JBOSS_KIE_ARGS == *"${expected_ejb_timer_tx}"* ]]
  [[ $JBOSS_KIE_ARGS == *"${expected_ejb_timer_local_cache}"* ]]
}

@test "verify if EJB_TIMER related settings are changed" {
  local TIMER_SERVICE_DATA_STORE="EJB_TIMER"
  local JBPM_EJB_TIMER_TX="false"
  local JBPM_EJB_TIMER_LOCAL_CACHE="true"
  local expected_ejb_timer_tx="-Dorg.jbpm.ejb.timer.tx=false"
  local expected_ejb_timer_local_cache="-Dorg.jbpm.ejb.timer.local.cache=true"
  configure_EJB_Timer_datasource >&2
  echo "Result is ${JBOSS_KIE_ARGS}"
  [[ $JBOSS_KIE_ARGS == *"${expected_ejb_timer_tx}"* ]]
  [[ $JBOSS_KIE_ARGS == *"${expected_ejb_timer_local_cache}"* ]]
}

@test "verify if EJB_TIMER is correctly configured with data-sources using URL param when driver is mariadb" {
  local expected_timer_service="EJB_TIMER"
  local expected_datasources="EJB_TIMER,RHPAM"
  export DATASOURCES="RHPAM"
  export RHPAM_DRIVER="mariadb"
  export RHPAM_USERNAME="rhpam-user"
  export RHPAM_PASSWORD="rhpam-pwd"
  export RHPAM_URL="jdbc:mariadb://myapp-host:3306/rhpam-mariadb?useSSL=false"
  export RHPAM_JNDI="jboss:/datasources/rhpam"
  export RHPAM_JTA="true"
  configure_EJB_Timer_datasource >&2
  echo "EJBTimer url is ${EJB_TIMER_XA_CONNECTION_PROPERTY_Url} " >&2
  echo "RHPAM url is ${RHPAM_URL} " >&2
  [ "${TIMER_SERVICE_DATA_STORE^^}" = "${expected_timer_service}" ]
  [ "${DATASOURCES}" = "${expected_datasources}" ]
  [ "${EJB_TIMER_DRIVER}" = "${RHPAM_DRIVER}" ]
  [ "${RHPAM_URL}" = "\<\![CDATA[jdbc:mariadb://myapp-host:3306/rhpam-mariadb?useSSL=false&enabledSslProtocolSuites=TLSv1.2]]\>" ]
  # we do not expect that this var is set anymore, since we're using URL property directly
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_PinGlobalTxToPhysicalConnection}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_EnabledSslProtocolSuites}" = "" ]
  # the URL property must be set
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_Url}" = "jdbc:mariadb://myapp-host:3306/rhpam-mariadb?useSSL=false\&amp;pinGlobalTxToPhysicalConnection=true\&amp;enabledSslProtocolSuites=TLSv1.2" ]
}

@test "verify if EJB_TIMER is correctly configured with data-sources using URL with multiple params when driver is mariadb" {
  local expected_timer_service="EJB_TIMER"
  local expected_datasources="EJB_TIMER,RHPAM"
  export DATASOURCES="RHPAM"
  export RHPAM_DRIVER="mariadb"
  export RHPAM_USERNAME="rhpam-user"
  export RHPAM_PASSWORD="rhpam-pwd"
  export RHPAM_URL="jdbc:mariadb://myapp-host:3306/rhpam-mariadb?useSSL=false&secondParam=value"
  export RHPAM_JNDI="jboss:/datasources/rhpam"
  export RHPAM_JTA="true"
  configure_EJB_Timer_datasource >&2
  echo "EJBTimer url is ${EJB_TIMER_XA_CONNECTION_PROPERTY_Url} " >&2
  echo "RHPAM url is ${RHPAM_URL} " >&2
  [ "${TIMER_SERVICE_DATA_STORE^^}" = "${expected_timer_service}" ]
  [ "${DATASOURCES}" = "${expected_datasources}" ]
  [ "${EJB_TIMER_DRIVER}" = "${RHPAM_DRIVER}" ]
  [ "${RHPAM_URL}" = "\<\![CDATA[jdbc:mariadb://myapp-host:3306/rhpam-mariadb?useSSL=false&secondParam=value&enabledSslProtocolSuites=TLSv1.2]]\>" ]
  # we do not expect that this var is set anymore, since we're using URL property directly
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_PinGlobalTxToPhysicalConnection}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_EnabledSslProtocolSuites}" = "" ]
  # the URL property must be set
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_Url}" = "jdbc:mariadb://myapp-host:3306/rhpam-mariadb?useSSL=false\&amp;secondParam=value\&amp;pinGlobalTxToPhysicalConnection=true\&amp;enabledSslProtocolSuites=TLSv1.2" ]
}

@test "verify if EJB_TIMER is correctly configured with data-sources when driver is mysql" {
  local expected_timer_service="EJB_TIMER"
  local expected_datasources="EJB_TIMER,RHPAM"
  export DATASOURCES="RHPAM"
  export RHPAM_DRIVER="mysql"
  export RHPAM_DATABASE="rhpam-mysql"
  export RHPAM_USERNAME="rhpam-user"
  export RHPAM_PASSWORD="rhpam-pwd"
  export RHPAM_SERVICE_HOST="myapp-host"
  export RHPAM_SERVICE_PORT="3306"
  export RHPAM_JNDI="jboss:/datasources/rhpam"
  export RHPAM_JTA="true"
  configure_EJB_Timer_datasource >&2
  echo "EJBTimer url is ${EJB_TIMER_XA_CONNECTION_PROPERTY_URL} " >&2
  echo "RHPAM url is ${RHPAM_URL} " >&2
  [ "${TIMER_SERVICE_DATA_STORE^^}" = "${expected_timer_service}" ]
  [ "${DATASOURCES}" = "${expected_datasources}" ]
  [ "${EJB_TIMER_DRIVER}" = "${RHPAM_DRIVER}" ]
  [ "${RHPAM_URL}" = "jdbc:mysql://myapp-host:3306/rhpam-mysql?enabledTLSProtocols=TLSv1.2" ]
  # we do not expect that this var is set anymore, since we're using URL property directly
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_PinGlobalTxToPhysicalConnection}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_EnabledSslProtocolSuites}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_EnabledTLSProtocols}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_ServerName}" = "${RHPAM_SERVICE_HOST}" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_DatabaseName}" = "${RHPAM_DATABASE}" ]
  # the URL property must be set
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_URL}" = "jdbc:mysql://myapp-host:3306/rhpam-mysql?pinGlobalTxToPhysicalConnection=true\&amp;enabledTLSProtocols=TLSv1.2" ]
}

@test "verify if EJB_TIMER is correctly configured with data-sources using URL param when driver is mysql" {
  local expected_timer_service="EJB_TIMER"
  local expected_datasources="EJB_TIMER,RHPAM"
  export DATASOURCES="RHPAM"
  export RHPAM_DRIVER="mysql"
  export RHPAM_USERNAME="rhpam-user"
  export RHPAM_PASSWORD="rhpam-pwd"
  export RHPAM_URL="jdbc:mysql://myapp-host:3306/rhpam-mysql?useSSL=false"
  export RHPAM_JNDI="jboss:/datasources/rhpam"
  export RHPAM_JTA="true"
  configure_EJB_Timer_datasource >&2
  echo "EJBTimer url is ${EJB_TIMER_XA_CONNECTION_PROPERTY_URL} " >&2
  echo "RHPAM url is ${RHPAM_URL} " >&2
  [ "${TIMER_SERVICE_DATA_STORE^^}" = "${expected_timer_service}" ]
  [ "${DATASOURCES}" = "${expected_datasources}" ]
  [ "${EJB_TIMER_DRIVER}" = "${RHPAM_DRIVER}" ]
  [ "${RHPAM_URL}" = "\<\![CDATA[jdbc:mysql://myapp-host:3306/rhpam-mysql?useSSL=false&enabledTLSProtocols=TLSv1.2]]\>" ]
  # we do not expect that this var is set anymore, since we're using URL property directly
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_PinGlobalTxToPhysicalConnection}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_EnabledSslProtocolSuites}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_EnabledTLSProtocols}" = "" ]
  # the URL property must be set
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_URL}" = "jdbc:mysql://myapp-host:3306/rhpam-mysql?useSSL=false\&amp;pinGlobalTxToPhysicalConnection=true\&amp;enabledTLSProtocols=TLSv1.2" ]
}

@test "verify if EJB_TIMER is correctly configured with data-sources using URL using multiple params when driver is mysql" {
  local expected_timer_service="EJB_TIMER"
  local expected_datasources="EJB_TIMER,RHPAM"
  export DATASOURCES="RHPAM"
  export RHPAM_DRIVER="mysql"
  export RHPAM_USERNAME="rhpam-user"
  export RHPAM_PASSWORD="rhpam-pwd"
  export RHPAM_URL="jdbc:mysql://myapp-host:3306/rhpam-mysql?useSSL=false&secondParam=value"
  export RHPAM_JNDI="jboss:/datasources/rhpam"
  export RHPAM_JTA="true"
  configure_EJB_Timer_datasource >&2
  echo "EJBTimer url is ${EJB_TIMER_XA_CONNECTION_PROPERTY_URL} " >&2
  echo "RHPAM url is ${RHPAM_URL} " >&2
  [ "${TIMER_SERVICE_DATA_STORE^^}" = "${expected_timer_service}" ]
  [ "${DATASOURCES}" = "${expected_datasources}" ]
  [ "${EJB_TIMER_DRIVER}" = "${RHPAM_DRIVER}" ]
  [ "${RHPAM_URL}" = "\<\![CDATA[jdbc:mysql://myapp-host:3306/rhpam-mysql?useSSL=false&secondParam=value&enabledTLSProtocols=TLSv1.2]]\>" ]
  # we do not expect that this var is set anymore, since we're using URL property directly
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_PinGlobalTxToPhysicalConnection}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_EnabledSslProtocolSuites}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_EnabledTLSProtocols}" = "" ]
  # the URL property must be set
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_URL}" = "jdbc:mysql://myapp-host:3306/rhpam-mysql?useSSL=false\&amp;secondParam=value\&amp;pinGlobalTxToPhysicalConnection=true\&amp;enabledTLSProtocols=TLSv1.2" ]
}

@test "Checks if the EJB Timer was successfully configured with MySQL with DATASOURCES env using custom driver name and URL" {
  local expected_timer_service="EJB_TIMER"
  local expected_datasources="EJB_TIMER,TEST"
  export DATASOURCES=TEST
  export TEST_DATABASE=bpms
  export TEST_USERNAME=bpmUser
  export TEST_PASSWORD=bpmPass
  export TEST_DRIVER=mysql57
  export TEST_URL=jdbc:mysql://10.1.1.1:3306/bpms
  export TEST_NONXA=true
  export TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL=10000

  configure_EJB_Timer_datasource >&2
  echo "EJBTimer url is ${EJB_TIMER_XA_CONNECTION_PROPERTY_URL} " >&2
  echo "TEST url is ${TEST_URL} " >&2

  [ "${TIMER_SERVICE_DATA_STORE^^}" = "${expected_timer_service}" ]
  [ "${DATASOURCES}" = "${expected_datasources}" ]
  [ "${EJB_TIMER_DRIVER}" = "${TEST_DRIVER}" ]
  [ "${TEST_URL}" = "jdbc:mysql://10.1.1.1:3306/bpms?enabledTLSProtocols=TLSv1.2" ]
  # we do not expect that this var is set anymore, since we're using URL property directly
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_PinGlobalTxToPhysicalConnection}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_EnabledSslProtocolSuites}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_EnabledTLSProtocols}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_ServerName}" = "${RHPAM_SERVICE_HOST}" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_DatabaseName}" = "${RHPAM_DATABASE}" ]
  # the URL property must be set
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_URL}" = "jdbc:mysql://10.1.1.1:3306/bpms?pinGlobalTxToPhysicalConnection=true\&amp;enabledTLSProtocols=TLSv1.2" ]
}


@test "verify that when an user set the property pinGlobalTxToPhysicalConnection manually, the XA Datasource is not created with it" {
  local expected_timer_service="EJB_TIMER"
  local expected_datasources="EJB_TIMER,RHPAM"
  export RHPAM_XA_CONNECTION_PROPERTY_PinGlobalTxToPhysicalConnection="true"
  export EJB_TIMER_XA_CONNECTION_PROPERTY_PinGlobalTxToPhysicalConnection="true"
  export DATASOURCES="RHPAM"
  export RHPAM_DRIVER="mysql"
  export RHPAM_DATABASE="rhpam-mysql"
  export RHPAM_USERNAME="rhpam-user"
  export RHPAM_PASSWORD="rhpam-pwd"
  export RHPAM_SERVICE_HOST="myapp-host"
  export RHPAM_SERVICE_PORT="3306"
  export RHPAM_JNDI="jboss:/datasources/rhpam"
  export RHPAM_JTA="true"
  configure_EJB_Timer_datasource >&2
  echo "EJBTimer url is ${EJB_TIMER_XA_CONNECTION_PROPERTY_URL} " >&2
  echo "RHPAM url is ${RHPAM_URL} " >&2
  [ "${TIMER_SERVICE_DATA_STORE^^}" = "${expected_timer_service}" ]
  [ "${DATASOURCES}" = "${expected_datasources}" ]
  [ "${EJB_TIMER_DRIVER}" = "${RHPAM_DRIVER}" ]
  [ "${RHPAM_URL}" = "jdbc:mysql://myapp-host:3306/rhpam-mysql?enabledTLSProtocols=TLSv1.2" ]
  # we do not expect that this var is set anymore, since we're using URL property directly
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_PinGlobalTxToPhysicalConnection}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_EnabledSslProtocolSuites}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_EnabledTLSProtocols}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_ServerName}" = "${RHPAM_SERVICE_HOST}" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_DatabaseName}" = "${RHPAM_DATABASE}" ]
  # the URL property must be set
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_URL}" = "jdbc:mysql://myapp-host:3306/rhpam-mysql?pinGlobalTxToPhysicalConnection=true\&amp;enabledTLSProtocols=TLSv1.2" ]
}

@test "verify if EJB_TIMER is correctly configured with data-sources when driver is postgresql" {
  local expected_timer_service="EJB_TIMER"
  local expected_datasources="EJB_TIMER,RHPAM"
  export DATASOURCES="RHPAM"
  export RHPAM_DRIVER="postgresql"
  export RHPAM_DATABASE="rhpam-postgresql"
  export RHPAM_USERNAME="rhpam-user"
  export RHPAM_PASSWORD="rhpam-pwd"
  export RHPAM_SERVICE_HOST="myapp-host"
  export RHPAM_SERVICE_PORT="5432"
  export RHPAM_JNDI="jboss:/datasources/rhpam"
  export RHPAM_JTA="true"
  configure_EJB_Timer_datasource >&2
  echo "EJBTimer url is ${EJB_TIMER_XA_CONNECTION_PROPERTY_Url} " >&2
  [ "${TIMER_SERVICE_DATA_STORE^^}" = "${expected_timer_service}" ]
  [ "${DATASOURCES}" = "${expected_datasources}" ]
  [ "${EJB_TIMER_DRIVER}" = "${RHPAM_DRIVER}" ]
  [ "${RHPAM_URL}" = "jdbc:${RHPAM_DRIVER}://${RHPAM_SERVICE_HOST}:${RHPAM_SERVICE_PORT}/${RHPAM_DATABASE}" ]
  # we do not expect that this var is set anymore, since we're using URL property directly
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_PinGlobalTxToPhysicalConnection}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_EnabledSslProtocolSuites}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_ServerName}" = "${RHPAM_SERVICE_HOST}" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_DatabaseName}" = "${RHPAM_DATABASE}" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_PortNumber}" = "${RHPAM_SERVICE_PORT}" ]
  # the URL property must not be set
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_Url}" = "" ]
}

@test "verify EJB_TIMER is configured by passing DB_PREFIX" {
  unset EJB_TIMER_XA_CONNECTION_PROPERTY_ServerName
  unset EJB_TIMER_XA_CONNECTION_PROPERTY_DatabaseName
  unset EJB_TIMER_XA_CONNECTION_PROPERTY_PortNumber
  unset EJB_TIMER_XA_CONNECTION_PROPERTY_Url
  export DB_SERVICE_PREFIX_MAPPING="kie-app-postgresql=DB"
  export DB_DRIVER="postgresql"
  export DB_DATABASE="bpms"
  export DB_USERNAME="bpmUser"
  export DB_PASSWORD="bpmPass"
  export DB_JNDI="java:jboss/datasources/ExampleDS"
  export DB_NONXA="true"
  export KIE_APP_POSTGRESQL_SERVICE_HOST="10.1.1.1"
  export KIE_APP_POSTGRESQL_SERVICE_PORT="5432"
  export TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL="10000"
  configure_EJB_Timer_datasource >&2
  echo "ServerName is ${EJB_TIMER_XA_CONNECTION_PROPERTY_ServerName} " >&2
  [ "${EJB_TIMER_DRIVER}" = "${DB_DRIVER}" ]
  [ "${DB_URL}" = "jdbc:${DB_DRIVER}://${KIE_APP_POSTGRESQL_SERVICE_HOST}:${KIE_APP_POSTGRESQL_SERVICE_PORT}/${DB_DATABASE}" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_ServerName}" = "${KIE_APP_POSTGRESQL_SERVICE_HOST}" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_DatabaseName}" = "${DB_DATABASE}" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_PortNumber}" = "${KIE_APP_POSTGRESQL_SERVICE_PORT}" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_Url}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_URL}" = "" ]
}

@test "verify EJB_TIMER is configured by passing XA parameters for mysql datasources" {
  unset EJB_TIMER_XA_CONNECTION_PROPERTY_ServerName
  unset EJB_TIMER_XA_CONNECTION_PROPERTY_DatabaseName
  unset EJB_TIMER_XA_CONNECTION_PROPERTY_PortNumber
  unset EJB_TIMER_XA_CONNECTION_PROPERTY_Port
  unset EJB_TIMER_XA_CONNECTION_PROPERTY_Url
  local expected_timer_service="EJB_TIMER"
  local expected_datasources="EJB_TIMER,RHPAM"
  export DATASOURCES="RHPAM"
  export RHPAM_DRIVER="mysql"
  export RHPAM_USER="rhpam-user"
  export RHPAM_PASSWORD="rhpam-pwd"
  export RHPAM_XA_CONNECTION_PROPERTY_ServerName="myapp-host"
  export RHPAM_XA_CONNECTION_PROPERTY_Port="3306"
  export RHPAM_XA_CONNECTION_PROPERTY_DatabaseName="rhpam-mysql"
  export RHPAM_XA_CONNECTION_PROPERTY_PinGlobalTxToPhysicalConnection="true"
  export RHPAM_XA_CONNECTION_PROPERTY_EnabledTLSProtocols="TLSv1.2"
  export RHPAM_XA_CONNECTION_PROPERTY_JNDI="jboss:/datasources/rhpam"
  export RHPAM_JTA="true"
  configure_EJB_Timer_datasource >&2
  echo -en "EJB_TIMER env are: \n $(env | grep -i ejb_timer | sort -u) \n" >&2
  log_info "EJB_TIMER_XA_CONNECTION_PROPERTY_URL is ${EJB_TIMER_XA_CONNECTION_PROPERTY_URL}"
  [ "${TIMER_SERVICE_DATA_STORE^^}" = "${expected_timer_service}" ]
  [ "${DATASOURCES}" = "${expected_datasources}" ]
  [ "${EJB_TIMER_DRIVER}" = "${RHPAM_DRIVER}" ]
  # we do not expect that this var is set anymore, since we're using URL property directly
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_PinGlobalTxToPhysicalConnection}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_EnabledSslProtocolSuites}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_EnabledTLSProtocols}" = "${RHPAM_XA_CONNECTION_PROPERTY_EnabledTLSProtocols}" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_ServerName}" = "${RHPAM_XA_CONNECTION_PROPERTY_ServerName}" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_DatabaseName}" = "${RHPAM_XA_CONNECTION_PROPERTY_DatabaseName}" ]
  # the URL property must be set
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_URL}" = "jdbc:${RHPAM_DRIVER}://${RHPAM_XA_CONNECTION_PROPERTY_ServerName}:${RHPAM_XA_CONNECTION_PROPERTY_Port}/${RHPAM_XA_CONNECTION_PROPERTY_DatabaseName}?pinGlobalTxToPhysicalConnection=true\&amp;enabledTLSProtocols=TLSv1.2" ]
}

@test "verify if EJB_TIMER is correctly configured with data-sources when driver is db2 using SERVICE envs" {
  local expected_timer_service="EJB_TIMER"
  local expected_datasources="EJB_TIMER,RHPAM"
  export DATASOURCES="RHPAM"
  export RHPAM_DRIVER="db2"
  export RHPAM_DATABASE="rhpam-db2"
  export RHPAM_USERNAME="rhpam-user"
  export RHPAM_PASSWORD="rhpam-pwd"
  export RHPAM_SERVICE_HOST="myapp-host"
  export RHPAM_SERVICE_PORT="50000"
  export RHPAM_JNDI="jboss:/datasources/rhpam"
  export RHPAM_JTA="true"
  configure_EJB_Timer_datasource >&2
  echo "RHPAM_URL url is ${RHPAM_URL} " >&2
  echo "jdbc:${RHPAM_DRIVER}://${RHPAM_SERVICE_HOST}:${RHPAM_SERVICE_PORT}/${RHPAM_DATABASE}"  >&2
  [ "${TIMER_SERVICE_DATA_STORE^^}" = "${expected_timer_service}" ]
  [ "${DATASOURCES}" = "${expected_datasources}" ]
  [ "${EJB_TIMER_DRIVER}" = "${RHPAM_DRIVER}" ]
  [ "${RHPAM_URL}" = "jdbc:${RHPAM_DRIVER}://${RHPAM_SERVICE_HOST}:${RHPAM_SERVICE_PORT}/${RHPAM_DATABASE}" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_ServerName}" = "${RHPAM_SERVICE_HOST}" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_DatabaseName}" = "${RHPAM_DATABASE}" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_PortNumber}" = "${RHPAM_SERVICE_PORT}" ]
  # the URL property must not be set
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_URL}" = "" ]
}

@test "verify if EJB_TIMER is correctly configured with data-sources when driver is db2 using URL" {
  local expected_timer_service="EJB_TIMER"
  local expected_datasources="EJB_TIMER,RHPAM"
  export DATASOURCES="RHPAM"
  export RHPAM_DRIVER="db2"
  export RHPAM_URL="jdbc:db2://myapp-host:50000/rhpam-db2"
  export RHPAM_USERNAME="rhpam-user"
  export RHPAM_PASSWORD="rhpam-pwd"
  export RHPAM_JNDI="jboss:/datasources/rhpam"
  export RHPAM_JTA="true"
  configure_EJB_Timer_datasource >&2
  echo "RHPAM_URL url is ${RHPAM_URL} " >&2
  [ "${TIMER_SERVICE_DATA_STORE^^}" = "${expected_timer_service}" ]
  [ "${DATASOURCES}" = "${expected_datasources}" ]
  [ "${EJB_TIMER_DRIVER}" = "${RHPAM_DRIVER}" ]
  [ "${RHPAM_URL}" = "jdbc:${RHPAM_DRIVER}://myapp-host:50000/rhpam-db2" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_ServerName}" = "myapp-host" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_DatabaseName}" = "rhpam-db2" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_PortNumber}" = "50000" ]
  # the URL property must not be set
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_URL}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_Url}" = "" ]
}

@test "verify if EJB_TIMER is correctly configured with xa-data-sources when driver is db2 using SERVICE envs" {
  local expected_timer_service="EJB_TIMER"
  local expected_datasources="EJB_TIMER,RHPAM"
  export DATASOURCES="RHPAM"
  export RHPAM_DRIVER="db2"
  export RHPAM_DATABASE="rhpam-db2"
  export RHPAM_USERNAME="rhpam-user"
  export RHPAM_PASSWORD="rhpam-pwd"
  export RHPAM_SERVICE_HOST="myapp-host"
  export RHPAM_SERVICE_PORT="50000"
  export RHPAM_JNDI="java:/jboss/datasources/rhpam"
  export RHPAM_JTA="true"
  export RHPAM_NONXA="false"
  configure_EJB_Timer_datasource >&2
  echo "RHPAM_URL url is ${RHPAM_URL} " >&2
  echo "RHPAM_XA_CONNECTION_PROPERTY_URL is ${RHPAM_XA_CONNECTION_PROPERTY_URL} " >&2
  echo "jdbc:${RHPAM_DRIVER}://${RHPAM_SERVICE_HOST}:${RHPAM_SERVICE_PORT}/${RHPAM_DATABASE}"  >&2
  [ "${TIMER_SERVICE_DATA_STORE^^}" = "${expected_timer_service}" ]
  [ "${DATASOURCES}" = "${expected_datasources}" ]
  [ "${EJB_TIMER_DRIVER}" = "${RHPAM_DRIVER}" ]
  [ "${RHPAM_URL}" = "" ]
  [ "${RHPAM_XA_CONNECTION_PROPERTY_URL}" = "" ]
  [ "${RHPAM_XA_CONNECTION_PROPERTY_ServerName}" = "${RHPAM_SERVICE_HOST}" ]
  [ "${RHPAM_XA_CONNECTION_PROPERTY_DatabaseName}" = "${RHPAM_DATABASE}" ]
  [ "${RHPAM_XA_CONNECTION_PROPERTY_PortNumber}" = "${RHPAM_SERVICE_PORT}" ]

  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_ServerName}" = "${RHPAM_SERVICE_HOST}" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_DatabaseName}" = "${RHPAM_DATABASE}" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_PortNumber}" = "${RHPAM_SERVICE_PORT}" ]
  # the URL property must not be set
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_URL}" = "" ]
}

@test "check if kie server location is set according to the route" {
  local expected="http://${HOSTNAME}:80/services/rest/server"
  KIE_SERVER_ROUTE_NAME="my-route-name"
  configure_server_location >&2
  echo "JBOSS_KIE_ARGS is ${JBOSS_KIE_ARGS}" >&2
  echo "Expected is ${expected}" >&2
  [[ $JBOSS_KIE_ARGS == *"-Dorg.kie.server.location=${expected}"* ]]
}

@test "check if kie server location is set to default" {
  local expected="http://${HOSTNAME}:8080/services/rest/server"
  configure_server_location >&2
  echo "JBOSS_KIE_ARGS is ${JBOSS_KIE_ARGS}" >&2
  echo "Expected is ${expected}" >&2
  [[ $JBOSS_KIE_ARGS == *"-Dorg.kie.server.location=${expected}"* ]]
}

@test "Check if the optaplanner thread pool queue size is set" {
    export OPTAPLANNER_SERVER_EXT_THREAD_POOL_QUEUE_SIZE="4"
    local expected="4"
    configure_optaplanner >&2
    echo "Result: ${JBOSS_KIE_ARGS}"
    echo "Expected: ${expected}"
    [[ $JBOSS_KIE_ARGS == *"-Dorg.optaplanner.server.ext.thread.pool.queue.size=${expected}"* ]]
}

@test "test controller access with default values" {
    KIE_SERVER_CONTROLLER_SERVICE="my-cool-service"
    # *_SERVICE_HOST are generated by k8s
    MY_COOL_SERVICE_SERVICE_HOST="10.10.10.10"

    local expected=" -Dorg.kie.server.controller=http://10.10.10.10:8080/rest/controller -Dorg.kie.server.controller.user=\"adminUser\" -Dorg.kie.server.controller.pwd=\"admin1!\""

    configure_controller_access

    echo "  Result: ${JBOSS_KIE_ARGS}"
    echo "Expected: ${expected}"
    [[ "${JBOSS_KIE_ARGS}" == "${expected}" ]]
}

@test "test controller access with default protocol and with port 9191" {
    KIE_SERVER_CONTROLLER_SERVICE="my-cool-service"
    # *_SERVICE_HOST are generated by k8s
    MY_COOL_SERVICE_SERVICE_HOST="10.10.10.10"
    KIE_SERVER_CONTROLLER_PORT="9191"
    local expected=" -Dorg.kie.server.controller=http://10.10.10.10:9191/rest/controller -Dorg.kie.server.controller.user=\"adminUser\" -Dorg.kie.server.controller.pwd=\"admin1!\""

    configure_controller_access

    echo "  Result: ${JBOSS_KIE_ARGS}"
    echo "Expected: ${expected}"
    [[ "${JBOSS_KIE_ARGS}" == "${expected}" ]]
}

@test "test controller access with custom host, port and protocol" {
    KIE_SERVER_CONTROLLER_HOST="my-cool-host"
    KIE_SERVER_CONTROLLER_PORT="443"
    KIE_SERVER_CONTROLLER_PROTOCOL="https"
    local expected=" -Dorg.kie.server.controller=https://my-cool-host:443/rest/controller -Dorg.kie.server.controller.user=\"adminUser\" -Dorg.kie.server.controller.pwd=\"admin1!\""

    configure_controller_access

    echo "  Result: ${JBOSS_KIE_ARGS}"
    echo "Expected: ${expected}"
    [[ "${JBOSS_KIE_ARGS}" == "${expected}" ]]
}


@test "test controller access with https protocol and default port" {
    KIE_SERVER_CONTROLLER_SERVICE="my-cool-service"
    # *_SERVICE_HOST are generated by k8s
    MY_COOL_SERVICE_SERVICE_HOST="10.10.10.10"
    KIE_SERVER_CONTROLLER_PROTOCOL="https"
    local expected=" -Dorg.kie.server.controller=https://10.10.10.10:8443/rest/controller -Dorg.kie.server.controller.user=\"adminUser\" -Dorg.kie.server.controller.pwd=\"admin1!\""

    configure_controller_access

    echo "Result: ${JBOSS_KIE_ARGS}"
    echo "Expected: ${expected}"
    [[ "${JBOSS_KIE_ARGS}" == "${expected}" ]]
}

@test "test controller access with ws protocol" {
    KIE_SERVER_CONTROLLER_SERVICE="my-cool-service"
    # *_SERVICE_HOST are generated by k8s
    MY_COOL_SERVICE_SERVICE_HOST="10.10.10.10"
    KIE_SERVER_CONTROLLER_PROTOCOL="ws"
    local expected=" -Dorg.kie.server.controller=ws://10.10.10.10:8080/websocket/controller -Dorg.kie.server.controller.user=\"adminUser\" -Dorg.kie.server.controller.pwd=\"admin1!\""

    configure_controller_access

    echo "Result: ${JBOSS_KIE_ARGS}"
    echo "Expected: ${expected}"
    [[ "${JBOSS_KIE_ARGS}" == "${expected}" ]]
}

@test "Test controller access with wss protocol and default port" {
    KIE_SERVER_CONTROLLER_SERVICE="my-cool-service"
    # *_SERVICE_HOST are generated by k8s
    MY_COOL_SERVICE_SERVICE_HOST="10.10.10.10"
    KIE_SERVER_CONTROLLER_PROTOCOL="wss"
    local expected=" -Dorg.kie.server.controller=wss://10.10.10.10:8443/websocket/controller -Dorg.kie.server.controller.user=\"adminUser\" -Dorg.kie.server.controller.pwd=\"admin1!\""

    configure_controller_access

    echo "Result: ${JBOSS_KIE_ARGS}"
    echo "Expected: ${expected}"
    [[ "${JBOSS_KIE_ARGS}" == "${expected}" ]]
}

@test "Test controller access with wss protocol and custom port" {
    KIE_SERVER_CONTROLLER_SERVICE="my-cool-service"
    # *_SERVICE_HOST are generated by k8s
    MY_COOL_SERVICE_SERVICE_HOST="10.10.10.10"
    KIE_SERVER_CONTROLLER_PORT="443"
    KIE_SERVER_CONTROLLER_PROTOCOL="wss"
    local expected=" -Dorg.kie.server.controller=wss://10.10.10.10:443/websocket/controller -Dorg.kie.server.controller.user=\"adminUser\" -Dorg.kie.server.controller.pwd=\"admin1!\""

    configure_controller_access

    echo "Result: ${JBOSS_KIE_ARGS}"
    echo "Expected: ${expected}"
    [[ "${JBOSS_KIE_ARGS}" == "${expected}" ]]
}

@test "test controller access with wss protocol, custom host and port" {
    KIE_SERVER_CONTROLLER_HOST="my-cool-host"
    KIE_SERVER_CONTROLLER_PORT="9443"
    KIE_SERVER_CONTROLLER_PROTOCOL="wss"
    local expected=" -Dorg.kie.server.controller=wss://my-cool-host:9443/websocket/controller -Dorg.kie.server.controller.user=\"adminUser\" -Dorg.kie.server.controller.pwd=\"admin1!\""

    configure_controller_access

    echo "  Result: ${JBOSS_KIE_ARGS}"
    echo "Expected: ${expected}"
    [[ "${JBOSS_KIE_ARGS}" == "${expected}" ]]
}

@test "verify if the GC_MAX_METASPACE_SIZE is set to 512 if KIE_SERVER_MAX_METASPACE_SIZE is not set" {
    configure_metaspace
    echo "GC_MAX_METASPACE_SIZE=${GC_MAX_METASPACE_SIZE}"
    [[ "${GC_MAX_METASPACE_SIZE}" == "512" ]]
}

@test "verify if the KIE_SERVER_MAX_METASPACE_SIZE is correctly set" {
    export KIE_SERVER_MAX_METASPACE_SIZE="2048"
    configure_metaspace
    echo "GC_MAX_METASPACE_SIZE=${GC_MAX_METASPACE_SIZE}"
    [[ "${GC_MAX_METASPACE_SIZE}" == "2048" ]]
}

@test "verify if the GC_MAX_METASPACE_SIZE is correctly set and bypass KIE_SERVER_MAX_METASPACE_SIZE env" {
    export GC_MAX_METASPACE_SIZE="4096"
    configure_metaspace

    echo "GC_MAX_METASPACE_SIZE=${GC_MAX_METASPACE_SIZE}"
    [[ "${GC_MAX_METASPACE_SIZE}" == "4096" ]]
}

@test "verify if the KIE_SERVER_MAX_METASPACE_SIZE takes precedence when KIESERVER_MAX_METASPACE_SIZE and GC_MAX_METASPACE_SIZE are set" {
    export KIE_SERVER_MAX_METASPACE_SIZE="4096"
    export GC_MAX_METASPACE_SIZE="2048"
    configure_metaspace
    echo "GC_MAX_METASPACE_SIZE=${GC_MAX_METASPACE_SIZE}"
    [[ "${GC_MAX_METASPACE_SIZE}" == "${KIE_SERVER_MAX_METASPACE_SIZE}" ]]
}

@test "Verify if the jbpm cache is contained in the standalone-openshift.xml when KIE_SERVER_JBPM_CLUSTER is true" {
  export CONFIG_FILE=${JBOSS_HOME}/standalone/configuration/standalone-openshift.xml
  export KIE_SERVER_JBPM_CLUSTER="true"
  export KIE_SERVER_JBPM_CLUSTER_TRANSPORT_LOCK_TIMEOUT="60000"
  configure_jbpm_cluster
  #this is the return of xmllint --xpath "//*[local-name()='cache-container'][@name='jbpm']" $CONFIG_FILE
  expected=$(cat <<EOF
<cache-container name="jbpm">
        <transport lock-timeout="60000"/>
        <replicated-cache name="nodes">
        <transaction mode="BATCH"/>
        </replicated-cache>
        <replicated-cache name="jobs">
        <transaction mode="BATCH"/>
        </replicated-cache>
        </cache-container>
EOF
)

 result=$(xmllint --xpath "//*[local-name()='cache-container'][@name='jbpm']" ${JBOSS_HOME}/standalone/configuration/standalone-openshift.xml)
  echo "Expected: ${expected}"
  echo "Result: ${result}"
  [ "${result}" = "${expected}" ]
}