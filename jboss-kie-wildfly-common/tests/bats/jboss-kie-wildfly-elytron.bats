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
    rm -rf $JBOSS_HOME
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

@test "test if the correct default application domain is set on the config file" {
    update_security_domain

    expected="<application-security-domain name=\"other\" security-domain=\"ApplicationDomain\"/>
<application-security-domain name=\"other\" security-domain=\"ApplicationDomain\"/>"
    result=$(xmllint --xpath "//*[local-name()='application-security-domain']" $CONFIG_FILE)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}

@test "test if the correct sso application domain is set on the config file" {
    export SSO_URL="http://test"
    update_security_domain

    expected="<application-security-domain name=\"other\" security-domain=\"ApplicationDomain\"/>"
    result=$(xmllint --xpath "//*[local-name()='application-security-domain']" $CONFIG_FILE)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]

}


@test "test if the kie_git_config file is correctly generated" {
    export JBOSS_PRODUCT="rhpam-businesscentral"
    export SSO_URL="https://test"
    export SSO_SECRET="web-secret"
    export SSO_REALM="sso-realm"
    configure_business_central_kie_git_config

    expected="{
    \"realm\": \"sso-realm\",
    \"auth-server-url\": \"https://test\",
    \"ssl-required\": \"external\",
    \"resource\": \"kie-git\",
    \"credentials\": {
        \"secret\": \"web-secret\"
    }
}"

    result=$(cat ${JBOSS_HOME}/kie_git_config.json)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]
}


@test "test if the kie_git_config file is correctly generated with public key" {
    export JBOSS_PRODUCT="rhpam-businesscentral"
    export SSO_URL="https://test"
    export SSO_SECRET="web-secret"
    export SSO_REALM="sso-realm"
    export SSO_PUBLIC_KEY="some-random-key"
    configure_business_central_kie_git_config

    expected="{
    \"realm\": \"sso-realm\",
    \"realm-public-key\": \"some-random-key\",
    \"auth-server-url\": \"https://test\",
    \"ssl-required\": \"external\",
    \"resource\": \"kie-git\",
    \"credentials\": {
        \"secret\": \"web-secret\"
    }
}"

    result=$(cat ${JBOSS_HOME}/kie_git_config.json)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]

}


@test "test if the kie_git_config file is correctly generated with public key for decisioncentral" {
    export JBOSS_PRODUCT="rhdm-decisioncentral"
    export SSO_URL="https://test"
    export SSO_SECRET="web-secret"
    export SSO_REALM="sso-realm"
    export SSO_PUBLIC_KEY="some-random-key"
    configure_business_central_kie_git_config

    expected="{
    \"realm\": \"sso-realm\",
    \"realm-public-key\": \"some-random-key\",
    \"auth-server-url\": \"https://test\",
    \"ssl-required\": \"external\",
    \"resource\": \"kie-git\",
    \"credentials\": {
        \"secret\": \"web-secret\"
    }
}"

    result=$(cat ${JBOSS_HOME}/kie_git_config.json)

    echo "expected: ${expected}"
    echo "result  : ${result}"
    [ "${expected}" = "${result}" ]

}


@test "test if the kie_git_config is configured if custom file is provided" {
    export JBOSS_PRODUCT="rhpam-businesscentral"
    mkdir ${JBOSS_HOME}/kie
    KIE_GIT_CONFIG_PATH="${JBOSS_HOME}/kie/my_git_kie_config.json"
    touch ${KIE_GIT_CONFIG_PATH}
    export SSO_URL="https://test"

    configure_business_central_kie_git_config

    echo "JBOSS_KIE_ARGS: ${JBOSS_KIE_ARGS}"
    [ "${JBOSS_KIE_ARGS}" = " -Dorg.uberfire.ext.security.keycloak.keycloak-config-file=/tmp/jboss_home/kie/my_git_kie_config.json" ]
}
