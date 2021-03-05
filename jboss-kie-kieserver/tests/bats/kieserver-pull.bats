#!/usr/bin/env bats

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
# sets MAVEN_OPTS to fix /home/circleci/project/jboss-kie-kieserver/tests/bats/../../added/launch/kieserver-pull.sh: line 39: /opt/run-java/java-default-options: No such file or directory
export MAVEN_OPTS=" -XX:+TieredCompilation -XX:TieredStopAtLevel=1"
mkdir -p $JBOSS_HOME/bin/launch
mkdir -p ${JBOSS_HOME}/standalone/deployments

cp $BATS_TEST_DIRNAME/../../../tests/bats/common/logging.bash $JBOSS_HOME/bin/launch/logging.sh
cp $BATS_TEST_DIRNAME/../../../tests/bats/common/launch-common.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../jboss-kie-common/added/launch/jboss-kie-common.sh $JBOSS_HOME/bin/launch/jboss-kie-common.sh
cp $BATS_TEST_DIRNAME/../../../jboss-kie-wildfly-common/added/launch/jboss-kie-wildfly-common.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../jboss-kie-wildfly-common/added/launch/jboss-kie-wildfly-security.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../added/launch/kieserver-env.sh $JBOSS_HOME/bin/launch/kieserver-env.sh

teardown() {
    rm -rf $JBOSS_HOME
}

@test "Verify if the warning message is correctly printed if there is no KIE_SERVER_CONTAINER_DEPLOYMENT set" {

    run bash $BATS_TEST_DIRNAME/../../added/launch/kieserver-pull.sh
    echo "result ${lines[@]}"

    [[ "${lines[0]}" == "[WARN]Warning: EnvVar KIE_SERVER_CONTAINER_DEPLOYMENT is missing." ]]
    [[ "${lines[1]}" == "[WARN]Example: export KIE_SERVER_CONTAINER_DEPLOYMENT='containerId(containerAlias)=groupId:artifactId:version|c2(n2)=g2:a2:v2'" ]]
}

@test "Verify if the pull dependencies is correctly disabled" {
    export KIE_SERVER_CONTAINER_DEPLOYMENT="test=org.package:mypackage:1.0"
    export KIE_SERVER_DISABLE_KC_PULL_DEPS=true

    run bash $BATS_TEST_DIRNAME/../../added/launch/kieserver-pull.sh
    echo "result ${lines[@]}"

    [[ "${lines[0]}" == "[INFO]Using standard EnvVar KIE_SERVER_CONTAINER_DEPLOYMENT: test=org.package:mypackage:1.0" ]]
    [[ "${lines[10]}" == "[WARN]Pull dependencies is disabled, skipping. Please make sure to provide all dependencies needed by the specified kjar." ]]
}

@test "Verify if the pull dependencies is correctly triggered" {
    export KIE_SERVER_CONTAINER_DEPLOYMENT="test=org.package:mypackage:1.0"

    run bash $BATS_TEST_DIRNAME/../../added/launch/kieserver-pull.sh
    echo "result ${lines[@]}"

    [[ "${lines[0]}" == "[INFO]Using standard EnvVar KIE_SERVER_CONTAINER_DEPLOYMENT: test=org.package:mypackage:1.0" ]]
    [[ "${lines[10]}" == *"[INFO]Attempting to pull dependencies for kjar 0 with"* ]]
}

@test "Verify if the pull dependencies is correctly triggered by setting the disable flag to false" {
    export KIE_SERVER_CONTAINER_DEPLOYMENT="test=org.package:mypackage:1.0"
    export KIE_SERVER_DISABLE_KC_PULL_DEPS=false

    run bash $BATS_TEST_DIRNAME/../../added/launch/kieserver-pull.sh
    echo "result ${lines[@]}"

    [[ "${lines[0]}" == "[INFO]Using standard EnvVar KIE_SERVER_CONTAINER_DEPLOYMENT: test=org.package:mypackage:1.0" ]]
    [[ "${lines[10]}" == *"[INFO]Attempting to pull dependencies for kjar 0 with"* ]]
}
