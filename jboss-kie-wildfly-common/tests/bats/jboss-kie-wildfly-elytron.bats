#!/usr/bin/env bats

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
export CONFIG_FILE=${JBOSS_HOME}/standalone/configuration/standalone-openshift.xml
mkdir -p $JBOSS_HOME/standalone/configuration
mkdir -p $JBOSS_HOME/bin/launch

cp $BATS_TEST_DIRNAME/../../../tests/bats/common/launch-common.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../tests/bats/common/logging.bash $JBOSS_HOME/bin/launch/logging.sh
cp $BATS_TEST_DIRNAME/../../../jboss-eap-config-openshift/EAP7.4.0/added/standalone-openshift.xml $JBOSS_HOME/standalone/configuration/standalone-openshift.xml

source $BATS_TEST_DIRNAME/../../added/launch/jboss-kie-wildfly-elytron.sh

teardown() {
    rm -rf $JBOSS_HOMEs
}

@test "[KIE Server] test if the default kie-fs-realm is correctly added" {
    export JBOSS_PRODUCT=rhpam-kieserver
    configure_kie_fs_realm

    expected="<filesystem-realm name=\"KieFsRealm\">
                    <file path=\"/opt/kie/data/kie-fs-realm-users\"/>                </filesystem-realm>"
    result=$(xmllint --xpath "//*[local-name()='filesystem-realm']" $CONFIG_FILE)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    echo "JBOSS_KIE_ARGS: ${JBOSS_KIE_ARGS}"
    [ "${expected}" = "${result}" ]
    [ "${JBOSS_KIE_ARGS}" = " -Dorg.kie.server.services.jbpm.security.filesystemrealm.folder-path=/opt/kie/data/kie-fs-realm-users" ]
}

@test "[KIE Server] test if the kie-fs-realm is correctly added with custom directory" {
    export JBOSS_PRODUCT=rhpam-kieserver
    export KIE_ELYTRON_FS_PATH=/tmp/test/kie-fs

    configure_kie_fs_realm

    expected="<filesystem-realm name=\"KieFsRealm\">
                    <file path=\"/tmp/test/kie-fs\"/>                </filesystem-realm>"
    result=$(xmllint --xpath "//*[local-name()='filesystem-realm']" $CONFIG_FILE)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    echo "JBOSS_KIE_ARGS: ${JBOSS_KIE_ARGS}"
    [ "${expected}" = "${result}" ]
    [ "${JBOSS_KIE_ARGS}" = " -Dorg.kie.server.services.jbpm.security.filesystemrealm.folder-path=/tmp/test/kie-fs" ]
}

@test "[WORKBENCH] test if the default kie-fs-realm is correctly added" {
    export JBOSS_PRODUCT=rhpam-businesscentral
    configure_kie_fs_realm

    expected="<filesystem-realm name=\"KieFsRealm\">
                    <file path=\"/opt/kie/data/kie-fs-realm-users\"/>                </filesystem-realm>"
    result=$(xmllint --xpath "//*[local-name()='filesystem-realm']" $CONFIG_FILE)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    echo "JBOSS_KIE_ARGS: ${JBOSS_KIE_ARGS}"
    [ "${expected}" = "${result}" ]
    [ "${JBOSS_KIE_ARGS}" = " -Dorg.uberfire.ext.security.management.wildfly.filesystem.folder-path=/opt/kie/data/kie-fs-realm-users -Dorg.uberfire.ext.security.management.wildfly.cli.folderPath=/opt/kie/data/kie-fs-realm-users" ]
}

@test "[WORKBENCH] test if the kie-fs-realm is correctly added with custom directory" {
    export JBOSS_PRODUCT=rhpam-businesscentral-monitoring
    export KIE_ELYTRON_FS_PATH=/tmp/test/kie-fs

    configure_kie_fs_realm

    expected="<filesystem-realm name=\"KieFsRealm\">
                    <file path=\"/tmp/test/kie-fs\"/>                </filesystem-realm>"
    result=$(xmllint --xpath "//*[local-name()='filesystem-realm']" $CONFIG_FILE)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    echo "JBOSS_KIE_ARGS: ${JBOSS_KIE_ARGS}"
    [ "${expected}" = "${result}" ]
    [ "${JBOSS_KIE_ARGS}" = " -Dorg.uberfire.ext.security.management.wildfly.filesystem.folder-path=/tmp/test/kie-fs -Dorg.uberfire.ext.security.management.wildfly.cli.folderPath=/tmp/test/kie-fs" ]
}

@test "[DASHBUILDER] test if the kie-fs-realm is correctly added with custom directory" {
    export JBOSS_PRODUCT=rhpam-dashbuilder
    export KIE_ELYTRON_FS_PATH=/tmp/test/kie-fs

    configure_kie_fs_realm

    expected="<filesystem-realm name=\"KieFsRealm\">
                    <file path=\"/tmp/test/kie-fs\"/>                </filesystem-realm>"
    result=$(xmllint --xpath "//*[local-name()='filesystem-realm']" $CONFIG_FILE)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    echo "JBOSS_KIE_ARGS: ${JBOSS_KIE_ARGS}"
    [ "${expected}" = "${result}" ]
    [ "${JBOSS_KIE_ARGS}" = " -Dorg.uberfire.ext.security.management.wildfly.filesystem.folder-path=/tmp/test/kie-fs -Dorg.uberfire.ext.security.management.wildfly.cli.folderPath=/tmp/test/kie-fs" ]
}