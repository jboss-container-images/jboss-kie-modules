#!/usr/bin/env bats

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
mkdir -p $JBOSS_HOME/bin/launch

cp $BATS_TEST_DIRNAME/../../../tests/bats/common/launch-common.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../tests/bats/common/logging.bash $JBOSS_HOME/bin/launch/logging.sh
cp $BATS_TEST_DIRNAME/../../../jboss-kie-common/added/launch/jboss-kie-common.sh $JBOSS_HOME/bin/launch/jboss-kie-common.sh
cp $BATS_TEST_DIRNAME/../../../jboss-kie-wildfly-common/added/launch/jboss-kie-wildfly-security-login-modules.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../jboss-kie-wildfly-common/added/launch/jboss-kie-wildfly-common.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../jboss-kie-wildfly-common/added/launch/jboss-kie-wildfly-security.sh $JBOSS_HOME/bin/launch

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
  export RHPAM_USERNAME="rhpam-user"
  export RHPAM_PASSWORD="rhpam-pwd"
  export RHPAM_SERVICE_HOST="myapp-host"
  export RHPAM_SERVICE_PORT="3306"
  export RHPAM_JNDI="jboss:/datasources/rhpam"
  export RHPAM_JTA="true"
  configure_EJB_Timer_datasource >&2
  echo "EJBTimer url is ${EJB_TIMER_XA_CONNECTION_PROPERTY_Url} " >&2
  [ "${TIMER_SERVICE_DATA_STORE^^}" = "${expected_timer_service}" ]
  [ "${DATASOURCES}" = "${expected_datasources}" ]
  [ "${EJB_TIMER_DRIVER}" = "${RHPAM_DRIVER}" ]
  [ "${RHPAM_URL}" = "jdbc:mariadb://myapp-host:3306/rhpam-mariadb?enabledSslProtocolSuites=TLSv1.2" ]
  # we do not expect that this var is set anymore, since we're using URL property directly
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_PinGlobalTxToPhysicalConnection}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_EnabledSslProtocolSuites}" = "" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_ServerName}" = "${RHPAM_SERVICE_HOST}" ]
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_DatabaseName}" = "${RHPAM_DATABASE}" ]
  # the URL property must be set
  [ "${EJB_TIMER_XA_CONNECTION_PROPERTY_Url}" = "jdbc:mariadb://myapp-host:3306/rhpam-mariadb?pinGlobalTxToPhysicalConnection=true\&amp;enabledSslProtocolSuites=TLSv1.2" ]
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

@test "test deserialization whitelist backward compatibility" {
    configure_jackson_deserialization_backward_compatibility >&2
    echo "Result: ${JBOSS_KIE_ARGS}"
    [[ $JBOSS_KIE_ARGS == *"-Djackson.deserialization.whitelist.packages=\"\""* ]]
}