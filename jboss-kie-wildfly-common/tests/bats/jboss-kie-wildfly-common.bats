#!/usr/bin/env bats

load jboss-kie-wildfly-common

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
mkdir -p $JBOSS_HOME/standalone/configuration
mkdir -p $JBOSS_HOME/bin/launch

cp $BATS_TEST_DIRNAME/../../../tests/bats/common/logging.bash $JBOSS_HOME/bin/launch/logging.sh
load $BATS_TEST_DIRNAME/../../added/launch/jboss-kie-wildfly-common.sh
export CONFIG_FILE=$JBOSS_HOME/standalone/configuration/standalone-openshift-logging.xml

setup() {
  cp $BATS_TEST_DIRNAME/../../../jboss-eap-config-openshift/EAP7.4.0/added/standalone-openshift.xml $CONFIG_FILE
}

echo "fake xml" > $JBOSS_HOME/bin/launch/settings-non-readable.xml
echo "<settings xmlns=\"http://maven.apache.org/SETTINGS/1.1.0\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
        xsi:schemaLocation=\"http://maven.apache.org/SETTINGS/1.1.0 http://maven.apache.org/xsd/settings-1.1.0.xsd\">
        <localRepository/>
        <interactiveMode/>
        <usePluginRegistry/>
        <offline/>
     </settings>" > $JBOSS_HOME/bin/launch/settings.xml

teardown() {
    rm -rf $JBOSS_HOME
}

setupFilesAndFoldersForCleanupTests(){
      mkdir -p  ${JBOSS_HOME}/domain
      mkdir -p  ${JBOSS_HOME}/migration
      mkdir -p  ${JBOSS_HOME}/.installation
      mkdir -p  ${JBOSS_HOME}/bin/init.d/
      touch ${JBOSS_HOME}/bin/test.bat
      touch ${JBOSS_HOME}/bin/test.ps1
      touch ${JBOSS_HOME}/bin/test.sh
      touch ${JBOSS_HOME}/bin/init.d/test.sh
      mkdir -p  ${JBOSS_HOME}/standalone/configuration/
      touch ${JBOSS_HOME}/standalone/configuration/standalone-full.xml
      touch ${JBOSS_HOME}/standalone/configuration/standalone-ha.xml
      touch ${JBOSS_HOME}/standalone/configuration/standalone-full-ha.xml
      touch ${JBOSS_HOME}/standalone/configuration/standalone-load-balancer.xml
      touch ${JBOSS_HOME}/standalone/configuration/standalone-openshift.xml
      touch ${JBOSS_HOME}/standalone/configuration/application-roles.properties
      touch ${JBOSS_HOME}/standalone/configuration/application-users.properties
      touch ${JBOSS_HOME}/standalone/configuration/mgmt-groups.properties
      touch ${JBOSS_HOME}/standalone/configuration/mgmt-users.properties
      touch ${JBOSS_HOME}/.installation/test.jar

}

@test "test if the MAVEN_SETTINGS_XML is correctly configured with default config" {
    expected=" -Dkie.maven.settings.custom=${HOME}/.m2/settings.xml"
    configure_maven_settings
    echo "expected=${expected}"
    echo "JBOSS_KIE_ARGS=$JBOSS_KIE_ARGS"
    [ "${JBOSS_KIE_ARGS}" = "${expected}" ]
}

@test "test if the MAVEN_SETTINGS_XML is correctly configured with a existent and valid settings.xml" {
    export MAVEN_SETTINGS_XML="/tmp/jboss_home/bin/launch/settings.xml"
    expected=" -Dkie.maven.settings.custom=/tmp/jboss_home/bin/launch/settings.xml"
    configure_maven_settings
    echo "expected=${expected}"
    echo "JBOSS_KIE_ARGS=$JBOSS_KIE_ARGS"
    echo "${lines[@]}"
    [ "${JBOSS_KIE_ARGS}" = "${expected}" ]
}

@test "test if the MAVEN_SETTINGS_XML is correctly configured with non existent settings.xml" {
    export MAVEN_SETTINGS_XML="/fake/path"
    expected=" -Dkie.maven.settings.custom=${HOME}/.m2/settings.xml"
    configure_maven_settings || true
    echo "expected=${expected}"
    echo "JBOSS_KIE_ARGS=$JBOSS_KIE_ARGS"
    echo "${lines[@]}"
    echo $output
    [ "${JBOSS_KIE_ARGS}" = "${expected}" ]
}

@test "test if the MAVEN_SETTINGS_XML is correctly configured with a existent and not valid settings.xml" {
    export MAVEN_SETTINGS_XML="/tmp/jboss_home/bin/launch/settings-non-readable.xml"
    expected=" -Dkie.maven.settings.custom=${HOME}/.m2/settings.xml"
    configure_maven_settings || true
    echo "expected=${expected}"
    echo "JBOSS_KIE_ARGS=$JBOSS_KIE_ARGS"
    echo $output
    [ "${JBOSS_KIE_ARGS}" = "${expected}" ]
}

@test "verify if the JAVA_MAX_MEM_RATIO is set to 80 and JAVA_INITIAL_MEM_RATIO is set to 25" {
    configure_mem_ratio
    [[ "${JAVA_MAX_MEM_RATIO}" == 80 ]]
    [[ "${JAVA_INITIAL_MEM_RATIO}" == 25 ]]
}

@test "verify if the JAVA_MAX_MEM_RATIO is set with the values passed" {
    export JAVA_INITIAL_MEM_RATIO=10
    export JAVA_MAX_MEM_RATIO=25
    configure_mem_ratio
    [[ "${JAVA_MAX_MEM_RATIO}" == 25 ]]
    [[ "${JAVA_INITIAL_MEM_RATIO}" == 10 ]]
    unset JAVA_INITIAL_MEM_RATIO
    unset JAVA_MAX_MEM_RATIO
}

@test "verify if the logger pattern  is correctly configured with a custom pattern" {
    export LOGGER_PATTERN="%d{yyyy-MM-dd HH:mm:ss.SSS} %-5p [%c{1}] %m%n"
    configure_formatter

    expected="<pattern-formatter pattern=\"%d{yyyy-MM-dd HH:mm:ss.SSS} %-5p [%c{1}] %m%n\"/>"

    result=$(xmllint -xpath "//*[local-name()='subsystem']//*[local-name()='formatter']//*[local-name()='pattern-formatter']" $CONFIG_FILE)
    echo "Expected: ${expected}"
    echo "Result: ${result}"
    [ "${expected}" = "${result}" ]
}

@test "verify if the logger pattern  is correctly configured if none is provided" {
    configure_formatter
    expected="<pattern-formatter pattern=\"%K{level}%d{HH:mm:ss,SSS} %-5p [%c] (%t) %s%e%n\"/>"

    result=$(xmllint -xpath "//*[local-name()='subsystem']//*[local-name()='formatter']//*[local-name()='pattern-formatter']" $CONFIG_FILE)
    echo "Expected: ${expected}"
    echo "Result: ${result}"
    [ "${expected}" = "${result}" ]
}

@test "verify that domain, migration and .installation are deleted without errors and bin & configurations folders is cleaned up correctly" {

    setupFilesAndFoldersForCleanupTests

    function chown() { echo "mock-chown ${*}"; }
    function chmod() { echo "mock-chmod ${*}"; }

    export -f chmod
    export -f chown

    run bash $BATS_TEST_DIRNAME/../../configure.sh

    unset chmod
    unset chown

    # We have to delete folders domain and migration but not bin and standalone
    result="$(ls $JBOSS_HOME | wc -l)"
    [ "$result" -eq 2 ]

    # So let's check that there is the bin folder with 1 element
    result="$(ls $JBOSS_HOME/bin | wc -l)"
    [ "$result" -eq 2 ]

    # So let's check that there is an empty installation folder
    result="$(ls $JBOSS_HOME/.installation | wc -l)"
    [ "$result" -eq 0 ]

    # And that this element is not the init.d folder
    result="$(test -d $JBOSS_HOME/bin/init.d && echo "Found/Exists" || echo "Does not exist")"
    [ "$result" == "Does not exist" ]

    # So let's check that there is only the standalone-openshift-logging.xml
    # application-users.properties and application-roles.properties
    # in the standalone/configuration folder but no mgmt properties
    result="$(ls $JBOSS_HOME/standalone/configuration | wc -l)"
    [ "$result" -eq 4 ]

    # Let's verify that the standalone-openshift.xml is still there
    [ -f $JBOSS_HOME/standalone/configuration/standalone-openshift.xml ]



}

@test "verify that folders and files are deleted without errors even if migration folder doesn't exists" {

    setupFilesAndFoldersForCleanupTests

    function chown() { echo 'mock-chown ${*}'; }
    function chmod() { echo 'mock-chmod ${*}'; }

    export -f chmod
    export -f chown

    rm -rf ${JBOSS_HOME}/migration

    run bash $BATS_TEST_DIRNAME/../../configure.sh

    unset chmod
    unset chown

    # We have to delete folders domain and migration but not bin and standalone
    result="$(ls $JBOSS_HOME | wc -l)"
    [ "$result" -eq 2 ]

    # So let's check that there is the bin folder with 1 element
    result="$(ls $JBOSS_HOME/bin | wc -l)"
    [ "$result" -eq 2 ]

    # So let's check that there is an empty installation folder
    result="$(ls $JBOSS_HOME/.installation | wc -l)"
    [ "$result" -eq 0 ]

    # And that this element is not the init.d folder
    result="$(test -d $JBOSS_HOME/bin/init.d && echo "Found/Exists" || echo "Does not exist")"
    [ "$result" == "Does not exist" ]

    # So let's check that there is only the standalone-openshift-logging.xml
    # application-users.properties and application-roles.properties
    # in the standalone/configuration folder but no mgmt properties
    result="$(ls $JBOSS_HOME/standalone/configuration | wc -l)"
    [ "$result" -eq 4 ]

    # Let's verify that the standalone-openshift.xml is still there
    [ -f $JBOSS_HOME/standalone/configuration/standalone-openshift.xml ]
}