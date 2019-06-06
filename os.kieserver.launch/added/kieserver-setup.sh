#!/bin/sh
# if using vim, do ':set ft=zsh' for easier reading

source ${JBOSS_HOME}/bin/launch/logging.sh

function prepareEnv() {
    unset KIE_SERVER_JMS_QUEUES_REQUEST
    unset KIE_SERVER_JMS_QUEUES_RESPONSE
    unset KIE_SERVER_EXECUTOR_JMS_QUEUE
    unset KIE_SERVER_PERSISTENCE_DIALECT
    unset QUARTZ_JNDI
    unset KIE_SERVER_USER
    unset KIE_SERVER_PASSWORD
}

function configure() {
    setupKieServerForOpenShift
}

function generateKieServerStateXml() {
    java -jar $JBOSS_HOME/jboss-modules.jar -mp $JBOSS_HOME/modules $(getJBossModulesOptsForKieUtilities) org.openshift.kieserver.common.server.ServerConfig xml
}

function filterKieJmsFile() {
    kieJmsFile="${1}"
    if [ -e ${kieJmsFile} ] ; then
        sed -i "s,queue/KIE\.SERVER\.REQUEST,${KIE_SERVER_JMS_QUEUES_REQUEST},g" ${kieJmsFile}
        sed -i "s,queue/KIE\.SERVER\.RESPONSE,${KIE_SERVER_JMS_QUEUES_RESPONSE},g" ${kieJmsFile}
        sed -i "s,queue/KIE\.SERVER\.EXECUTOR,${KIE_SERVER_EXECUTOR_JMS_QUEUE},g" ${kieJmsFile}
    fi
}

function filterQuartzPropFile() {

    local QUARTZ_DELEGATE_CLASS="org.quartz.impl.jdbcjobstore.StdJDBCDelegate"
    local DEFAULT_JNDI
    local DB_TYPE

    quartzPropFile="${1}"
    if [ -e ${quartzPropFile} ] ; then


        # get the first db configuration using legacy datasource configuration:
        if [ "x${DB_SERVICE_PREFIX_MAPPING}" != "x" ]; then
            local serviceMappingName=${DB_SERVICE_PREFIX_MAPPING%%,*}
            local prefix=${serviceMappingName#*=}
            DEFAULT_JNDI=$(find_env "${prefix}_JNDI")
        fi
        # get the first db configuration using DATASOURCES env:
        if [ "x${DATASOURCES}" != "x" ]; then
            local prefix="${DATASOURCES%%,*}"
            DEFAULT_JNDI=$(find_env "${prefix}_JNDI")
        fi

        if [ "x${DEFAULT_JNDI}" != "x" ]; then
            quartzManagedJndiSet="true"
        fi
        if [ "x${QUARTZ_JNDI}" != "x" ]; then
            quartzNotManagedJndiSet="true"
        fi

        if [[ "${KIE_SERVER_PERSISTENCE_DIALECT}" == "org.hibernate.dialect.MySQL"* ]]; then
            quartzDriverDelegateSet="true"
            DB_TYPE="MYSQL"
        elif [[ "${KIE_SERVER_PERSISTENCE_DIALECT}" == "org.hibernate.dialect.PostgreSQL"* ]]; then
            QUARTZ_DELEGATE_CLASS="org.quartz.impl.jdbcjobstore.PostgreSQLDelegate"
            quartzDriverDelegateSet="true"
            DB_TYPE="POSTGRESQL"
        elif [[ "${KIE_SERVER_PERSISTENCE_DIALECT}" == *"Oracle"* ]]; then
            log_warning "For Oracle 10G use the org.jbpm.persistence.jpa.hibernate.DisabledFollowOnLockOracle10gDialect hibernate dialect to avoid frequent Hibernate warning HHH000444 message in the logs."
            QUARTZ_DELEGATE_CLASS="org.quartz.impl.jdbcjobstore.oracle.OracleDelegate"
            # Oracle classes needs to be accessible by the quartz, in this case oracle driver or module needs to be added on jboss-deployment-structure.xml file
            if [ "x${QUARTZ_DRIVER_MODULE}" != "x" ]; then
                sed -i "s|<\!--EXTRA_DEPENDENCY-->|<module name=\"${QUARTZ_DRIVER_MODULE}\"/>\n      <\!--EXTRA_DEPENDENCY-->|" $JBOSS_HOME/standalone/deployments/kie-server.war/WEB-INF/jboss-deployment-structure.xml
            else
                log_warning "QUARTZ_DRIVER_MODULE env not set. Quartz might not work properly."
            fi
            quartzDriverDelegateSet="true"
            DB_TYPE="ORACLE"
        elif [[ "${KIE_SERVER_PERSISTENCE_DIALECT}" == "org.hibernate.dialect.SQLServer"* ]]; then
            QUARTZ_DELEGATE_CLASS="org.quartz.impl.jdbcjobstore.MSSQLDelegate"
            quartzDriverDelegateSet="true"
            DB_TYPE="SQLSERVER"

            if [ "x${QUARTZ_DATABASE}" != "x" ]; then
                local databaseName="${QUARTZ_DATABASE}"
            fi

            if [ "x${QUARTZ_XA_CONNECTION_PROPERTY_URL}" != "x" ]; then
                local databaseName="${QUARTZ_XA_CONNECTION_PROPERTY_URL#*=}"
            fi

            if [ "x${QUARTZ_URL}" != "x" ]; then
                local databaseName="${QUARTZ_URL#*=}"
            fi

            sed -i "s|USE \[enter_db_name_here\]|USE ${databaseName}|" $JBOSS_HOME/bin/quartz_tables_sqlserver.sql

        elif [[ "${KIE_SERVER_PERSISTENCE_DIALECT}" == "org.hibernate.dialect.DB2"* ]]; then
            quartzDriverDelegateSet="true"
            DB_TYPE="DB2"
        fi

        if [ "${quartzDriverDelegateSet}" = "true" ] && [ "${quartzManagedJndiSet=}" = "true" ] && [ "${quartzNotManagedJndiSet=}" = "true" ]; then
            sed -i "s,org.quartz.jobStore.driverDelegateClass=,org.quartz.jobStore.driverDelegateClass=${QUARTZ_DELEGATE_CLASS}," ${quartzPropFile}
            sed -i "s,org.quartz.dataSource.managedDS.jndiURL=,org.quartz.dataSource.managedDS.jndiURL=${DEFAULT_JNDI}," ${quartzPropFile}
            sed -i "s,org.quartz.dataSource.notManagedDS.jndiURL=,org.quartz.dataSource.notManagedDS.jndiURL=${QUARTZ_JNDI}," ${quartzPropFile}
            KIE_SERVER_OPTS="${KIE_SERVER_OPTS} -Dorg.quartz.properties=${quartzPropFile} -Dorg.openshift.kieserver.common.sql.dbtype=${DB_TYPE}"
        fi
    fi
}

setupKieServerForOpenShift() {
    # source the KIE config
    source $JBOSS_HOME/bin/kieserver-config.sh
    # set the KIE environment
    setKieFullEnv
    # dump the KIE environment
    dumpKieFullEnv | tee ${JBOSS_HOME}/kieEnv

    # save the environment for use by the probes
    sed -ri "s/^([^:]+): *(.*)$/\1=\"\2\"/" ${JBOSS_HOME}/kieEnv

    # generate the KIE Server state file
    generateKieServerStateXml > "${KIE_SERVER_STATE_FILE}"

    # filter the KIE Server kie-server-jms.xml and ejb-jar.xml files
    filterKieJmsFile "${JBOSS_HOME}/standalone/deployments/kie-server.war/META-INF/kie-server-jms.xml"
    filterKieJmsFile "${JBOSS_HOME}/standalone/deployments/kie-server.war/WEB-INF/ejb-jar.xml"

    # setup the drivers, if exists
    configure_drivers

    # filter the KIE Server quartz.properties file
    filterQuartzPropFile "${JBOSS_HOME}/bin/quartz.properties"

    # CLOUD-758 - "Provider com.sun.script.javascript.RhinoScriptEngineFactory not found" is logged every time when a process uses Java Script.
    find $JBOSS_HOME/modules/system/layers/base -name javax.script.ScriptEngineFactory -exec sed -i "s|com.sun.script.javascript.RhinoScriptEngineFactory||" {} \;

    # append KIE Server options to JAVA_OPTS
    echo "# Append KIE Server options to JAVA_OPTS" >> $JBOSS_HOME/bin/standalone.conf
    echo "JAVA_OPTS=\"\$JAVA_OPTS ${KIE_SERVER_OPTS}\"" >> $JBOSS_HOME/bin/standalone.conf

    # add the KIE Server user
    $JBOSS_HOME/bin/add-user.sh -a -u "${KIE_SERVER_USER}" -p "${KIE_SERVER_PASSWORD}" -ro "kie-server,guest"
    if [ "$?" -ne "0" ]; then
        log_error "Failed to create the user ${KIE_SERVER_USER}"
        log_error "Exiting..."
        exit
    fi
}
