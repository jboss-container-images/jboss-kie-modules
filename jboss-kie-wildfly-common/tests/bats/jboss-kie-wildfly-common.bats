#!/usr/bin/env bats

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
mkdir -p $JBOSS_HOME/bin/launch

cp $BATS_TEST_DIRNAME/../../../tests/bats/common/logging.bash $JBOSS_HOME/bin/launch/logging.sh
load $BATS_TEST_DIRNAME/../../added/launch/jboss-kie-wildfly-common.sh

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
