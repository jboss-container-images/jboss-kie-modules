#!/usr/bin/env bats

load jboss-kie-wildfly-common

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
mkdir -p $JBOSS_HOME/bin/launch

export CONFIG_FILE=$JBOSS_HOME/standalone/configuration/standalone-openshift.xml

mkdir -p $JBOSS_HOME/standalone/configuration
cp $BATS_TEST_DIRNAME/../../../jboss-kie-wildfly-common/tests/bats/expectations/formatter/standalone-unformatted.xml $JBOSS_HOME/standalone/configuration/standalone-openshift.xml
cp $BATS_TEST_DIRNAME/../../../jboss-kie-wildfly-common/added/launch/jboss-kie-wildfly-config-files-formatter.sh $JBOSS_HOME/bin/launch


teardown() {
    rm -rf $JBOSS_HOME
}

@test "test if the standalone configuration file is correctly formmated" {
    run format_xml
    assert_xml ${CONFIG_FILE} $BATS_TEST_DIRNAME/expectations/formatter/standalone-expected.xml
}

