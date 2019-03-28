#!/usr/bin/env bats

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
export KIE_JMS_FILE=$JBOSS_HOME/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml
export KIE_EJB_JAR_FILE=$JBOSS_HOME/standalone/deployments/ROOT.war/WEB-INF/ejb-jar.xml
mkdir -p $JBOSS_HOME/bin/launch

cp $BATS_TEST_DIRNAME/../../../tests/bats/common/launch-common.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../tests/bats/common/logging.bash $JBOSS_HOME/bin/launch/logging.sh
mkdir -p $JBOSS_HOME/standalone/deployments/ROOT.war/{META-INF,WEB-INF}


#imports
source $BATS_TEST_DIRNAME/../../added/launch/jboss-kie-kieserver-jms.sh

setup() {
    cp $BATS_TEST_DIRNAME/resources/META-INF/kie-server-jms.xml ${KIE_JMS_FILE}
    cp $BATS_TEST_DIRNAME/../../added/WEB-INF/ejb-jar.xml ${KIE_EJB_JAR_FILE}
}

teardown() {
    rm -rf $JBOSS_HOME
}

@test "test default request/response queue values on META-INF/kie-server-jms.xml file" {
    expected_jms_queue_name=" name=\"KIE.SERVER.REQUEST\" name=\"KIE.SERVER.RESPONSE\" name=\"KIE.SERVER.EXECUTOR\""
    expected_entry_name="<entry name=\"queue/KIE.SERVER.REQUEST\"/><entry name=\"queue/KIE.SERVER.RESPONSE\"/><entry name=\"queue/KIE.SERVER.EXECUTOR\"/>"
    run configure
    result_entry_name=$(xmllint --xpath "//*[local-name()='jms-queue']//*[local-name()='entry']"[1] ${KIE_JMS_FILE})
    result_jms_queue_name=$(xmllint --xpath "//*[local-name()='jms-queue']/@name" ${KIE_JMS_FILE})
    echo "Expected: ${result_entry_name}"
    echo "Result: ${expected_entry_name}"
    [ "${result_entry_name}" = "${expected_entry_name}" ]
    echo "Expected: ${expected_jms_queue_name}"
    echo "Result: ${result_jms_queue_name}"
    [ "${result_jms_queue_name}" = "${expected_jms_queue_name}" ]
}


@test "test custom request/response queue values on META-INF/kie-server-jms.xml file" {
    KIE_SERVER_JMS_QUEUE_REQUEST="queue/MY.KIE.SERVER.REQUEST"
    KIE_SERVER_JMS_QUEUE_RESPONSE="queue/MY.KIE.SERVER.RESPONSE"
    KIE_SERVER_JMS_QUEUE_EXECUTOR="queue/MY.KIE.SERVER.EXECUTOR"
    expected_jms_queue_name=" name=\"MY.KIE.SERVER.REQUEST\" name=\"MY.KIE.SERVER.RESPONSE\" name=\"MY.KIE.SERVER.EXECUTOR\""
    expected_entry_name="<entry name=\"queue/MY.KIE.SERVER.REQUEST\"/><entry name=\"java:jboss/exported/jms/queue/MY.KIE.SERVER.REQUEST\"/><entry name=\"queue/MY.KIE.SERVER.RESPONSE\"/><entry name=\"java:jboss/exported/jms/queue/MY.KIE.SERVER.RESPONSE\"/><entry name=\"queue/MY.KIE.SERVER.EXECUTOR\"/>"
    run configure
    result_entry_name=$(xmllint --xpath "//*[local-name()='jms-queue']//*[local-name()='entry']" ${KIE_JMS_FILE})
    result_jms_queue_name=$(xmllint --xpath "//*[local-name()='jms-queue']/@name" ${KIE_JMS_FILE})
    echo "Expected: ${expected_entry_name}"
    echo "Result: ${result_entry_name}"
    [ "${result_entry_name}" = "${expected_entry_name}" ]
}


@test "test default request/executor queue values on WEB-INF/ejb-jar.xml file" {
    expected="<activation-config-property-value>queue/KIE.SERVER.REQUEST</activation-config-property-value><activation-config-property-value>queue/KIE.SERVER.REQUEST</activation-config-property-value><activation-config-property-value>javax.jms.Queue</activation-config-property-value><activation-config-property-value>Auto-acknowledge</activation-config-property-value><activation-config-property-value>queue/KIE.SERVER.EXECUTOR</activation-config-property-value><activation-config-property-value>javax.jms.Queue</activation-config-property-value><activation-config-property-value>Auto-acknowledge</activation-config-property-value>"
    run configure
    result=$(xmllint --xpath "//*[local-name()='activation-config-property-value']" ${KIE_EJB_JAR_FILE})
    echo "Expected: ${expected}"
    echo "Result: ${result}"
    [ "${result}" = "${expected}" ]
}

@test "test custom request/executor queue values on WEB-INF/ejb-jar.xml file" {
    KIE_SERVER_JMS_QUEUE_REQUEST="queue/MY.KIE.SERVER.REQUEST"
    KIE_SERVER_JMS_QUEUE_RESPONSE="queue/MY.KIE.SERVER.RESPONSE"
    KIE_SERVER_JMS_QUEUE_EXECUTOR="queue/MY.KIE.SERVER.EXECUTOR"
    expected="<activation-config-property-value>queue/MY.KIE.SERVER.REQUEST</activation-config-property-value><activation-config-property-value>queue/MY.KIE.SERVER.REQUEST</activation-config-property-value><activation-config-property-value>javax.jms.Queue</activation-config-property-value><activation-config-property-value>Auto-acknowledge</activation-config-property-value><activation-config-property-value>queue/MY.KIE.SERVER.EXECUTOR</activation-config-property-value><activation-config-property-value>javax.jms.Queue</activation-config-property-value><activation-config-property-value>Auto-acknowledge</activation-config-property-value>"
    run configure
    result=$(xmllint --xpath "//*[local-name()='activation-config-property-value']" ${KIE_EJB_JAR_FILE})
    echo "Expected: ${expected}"
    echo "Result: ${result}"
    [ "${result}" = "${expected}" ]
}

@test "test disabling the JMS executor" {
    KIE_SERVER_EXECUTOR_JMS="true"
    expected=""
    run configureJmsExecutor
    echo "Expected: ${expected}"
    echo "Result: ${JBOSS_KIE_ARGS}"
    echo "Output: ${output}"
    [ "${JBOSS_KIE_ARGS}" = "${expected}" ]
}

@test "test default signal queue configuration kie-jms-file" {
    KIE_SERVER_JMS_ENABLE_SIGNAL="true"
    expected_kie_jms_xml='<entry name="queue/KIE.SERVER.REQUEST"/><entry name="queue/KIE.SERVER.RESPONSE"/><entry name="queue/KIE.SERVER.EXECUTOR"/><entry name="queue/KIE.SERVER.SIGNAL"/>'
    run configureJmsSignal
    result_kie_jms_xml=$(xmllint --xpath "//*[local-name()='jms-queue']/*[local-name()='entry']"[1] ${KIE_JMS_FILE})
    echo "Expected kie jms file: ${expected_kie_jms_xml}"
    echo "Result kie jms file: ${result_kie_jms_xml}"
    [ "${result_kie_jms_xml}" = "${expected_kie_jms_xml}" ]
}

@test "test custom signal queue configuration kie-jms-file" {
    KIE_SERVER_JMS_ENABLE_SIGNAL="true"
    KIE_SERVER_JMS_QUEUE_SIGNAL="queue/CUSTOM.SIGNAL.QUEUE"
    expected_kie_jms_xml='<entry name="queue/KIE.SERVER.REQUEST"/><entry name="queue/KIE.SERVER.RESPONSE"/><entry name="queue/KIE.SERVER.EXECUTOR"/><entry name="queue/CUSTOM.SIGNAL.QUEUE"/>'
    run configureJmsSignal
    result_kie_jms_xml=$(xmllint --xpath "//*[local-name()='jms-queue']/*[local-name()='entry']"[1] ${KIE_JMS_FILE})
    echo "Expected kie jms file: ${expected_kie_jms_xml}"
    echo "Result kie jms file: ${result_kie_jms_xml}"
    cat ${KIE_JMS_FILE}
    [ "${result_kie_jms_xml}" = "${expected_kie_jms_xml}" ]
}

@test "test default signal queue configuration ejb-jar" {
    KIE_SERVER_JMS_ENABLE_SIGNAL="true"
    expected_ejb_jar="<activation-config-property-value>queue/KIE.SERVER.REQUEST</activation-config-property-value><activation-config-property-value>queue/KIE.SERVER.REQUEST</activation-config-property-value><activation-config-property-value>javax.jms.Queue</activation-config-property-value><activation-config-property-value>Auto-acknowledge</activation-config-property-value><activation-config-property-value>queue/KIE.SERVER.EXECUTOR</activation-config-property-value><activation-config-property-value>javax.jms.Queue</activation-config-property-value><activation-config-property-value>Auto-acknowledge</activation-config-property-value><activation-config-property-value>javax.jms.Queue</activation-config-property-value><activation-config-property-value>java:/queue/KIE.SERVER.SIGNAL</activation-config-property-value>"
    run configureJmsSignal
    result_ejb_jar=$(xmllint --xpath "//*[local-name()='activation-config-property-value']" ${KIE_EJB_JAR_FILE})
    echo "Expected ejb jar: ${expected_ejb_jar}"
    echo "Result ejb jar: ${result_ejb_jar}"
    [ "${result_ejb_jar}" = "${expected_ejb_jar}" ]
}

@test "test custom signal queue configuration ejb-jar" {
    KIE_SERVER_JMS_ENABLE_SIGNAL="true"
    KIE_SERVER_JMS_QUEUE_SIGNAL="queue/CUSTOM.SIGNAL.QUEUE"
    expected_ejb_jar="<activation-config-property-value>queue/KIE.SERVER.REQUEST</activation-config-property-value><activation-config-property-value>queue/KIE.SERVER.REQUEST</activation-config-property-value><activation-config-property-value>javax.jms.Queue</activation-config-property-value><activation-config-property-value>Auto-acknowledge</activation-config-property-value><activation-config-property-value>queue/KIE.SERVER.EXECUTOR</activation-config-property-value><activation-config-property-value>javax.jms.Queue</activation-config-property-value><activation-config-property-value>Auto-acknowledge</activation-config-property-value><activation-config-property-value>javax.jms.Queue</activation-config-property-value><activation-config-property-value>java:/queue/CUSTOM.SIGNAL.QUEUE</activation-config-property-value>"
    run configureJmsSignal
    result_ejb_jar=$(xmllint --xpath "//*[local-name()='activation-config-property-value']" ${KIE_EJB_JAR_FILE})
    echo "Expected ejb jar: ${expected_ejb_jar}"
    echo "Result ejb jar: ${result_ejb_jar}"
    [ "${result_ejb_jar}" = "${expected_ejb_jar}" ]
}


# keep this test as the last one
@test "Verify if the kie-server-jms.xml is removed when configuring external resource adapter." {
    MQ_SERVICE_PREFIX_MAPPING="AMQPREFIX"
    run postConfigure
    run ls -la /tmp/jboss_home/standalone/deployments/ROOT.war/META-INF/kie-server-jms.xml
    echo "status = ${status}"
    echo "output = ${output}"
    [ "${status}" = "2" ]
}