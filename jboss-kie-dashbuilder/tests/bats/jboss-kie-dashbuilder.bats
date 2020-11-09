#!/usr/bin/env bats

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
mkdir -p $JBOSS_HOME/bin/launch

cp $BATS_TEST_DIRNAME/../../../tests/bats/common/launch-common.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../tests/bats/common/logging.bash $JBOSS_HOME/bin/launch/logging.sh
cp $BATS_TEST_DIRNAME/../../../jboss-kie-common/added/launch/jboss-kie-common.sh $JBOSS_HOME/bin/launch/jboss-kie-common.sh
cp $BATS_TEST_DIRNAME/../../../jboss-kie-wildfly-common/added/launch/jboss-kie-wildfly-security.sh $JBOSS_HOME/bin/launch

#imports
source $BATS_TEST_DIRNAME/../../added/launch/jboss-kie-dashbuilder.sh

teardown() {
    rm -rf $JBOSS_HOME
}

# mock this func, no need to test it here
configure_dashbuilder_auth() {
    echo "configure_dashbuilder_auth - mocked func"
}


@test "test configure_dashbuilder_allow_external function with default value" {
    configure_dashbuilder_allow_external

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    [ "${JBOSS_KIE_DASHBUILDER_ARGS}" = " -Ddashbuilder.runtime.allowExternal=false" ]
}

@test "test configure_dashbuilder_allow_external function with custom value" {
    export DASHBUILDER_ALLOW_EXTERNAL_FILE_REGISTER="true"

    configure_dashbuilder_allow_external

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    [ "${JBOSS_KIE_DASHBUILDER_ARGS}" = " -Ddashbuilder.runtime.allowExternal=true" ]
}

@test "test configure_dashbuilder_allow_external function with invalid value" {
    export DASHBUILDER_ALLOW_EXTERNAL_FILE_REGISTER="nonsense"

    configure_dashbuilder_allow_external

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    [ "${JBOSS_KIE_DASHBUILDER_ARGS}" = " -Ddashbuilder.runtime.allowExternal=false" ]
}


@test "test configure_dashbuilder_component_partition function with default value" {
    configure_dashbuilder_partitions

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.components.partition=true"* ]]
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.dataset.partition=true"* ]]
}

@test "test configure_dashbuilder_component_partition function with custom value" {
    export DASHBUILDER_COMPONENT_PARTITION="false"
    export DASHBUILDER_DATASET_PARTITION="false"

    configure_dashbuilder_partitions

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.components.partition=false"* ]]
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.dataset.partition=false"* ]]
}

@test "test configure_dashbuilder_component_partition function with invalid value" {
    export DASHBUILDER_COMPONENT_PARTITION="nonsense"
    export DASHBUILDER_DATASET_PARTITION="nonsense"

    configure_dashbuilder_partitions

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.components.partition=true"* ]]
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.dataset.partition=true"* ]]
}

@test "test configure_dashbuilder_file_imports function with DASHBUILDER_IMPORT_FILE_LOCATION env" {
    export DASHBUILDER_IMPORT_FILE_LOCATION="/tmp/my_file.zip"
    configure_dashbuilder_file_imports

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = " -Ddashbuilder.runtime.import=/tmp/my_file.zip"* ]]
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" != *" -Ddashbuilder.import.base.dir"* ]]
}

@test "test configure_dashbuilder_file_imports function with no DASHBUILDER_IMPORT_FILE_LOCATION env" {
    configure_dashbuilder_file_imports

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" != "dashbuilder.runtime.import"* ]]
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.import.base.dir=/opt/kie/data/imports"* ]]
}

@test "test configure_dashbuilder_file_imports function with valid DASHBUILDER_IMPORTS_BASE_DIR env" {
    export DASHBUILDER_IMPORTS_BASE_DIR="/tmp"

    configure_dashbuilder_file_imports

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" != "dashbuilder.runtime.import"* ]]
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.import.base.dir=/tmp"* ]]
}

@test "test configure_dashbuilder_file_imports function with invalid DASHBUILDER_IMPORTS_BASE_DIR env" {
    export DASHBUILDER_IMPORTS_BASE_DIR="/nonsese"

    configure_dashbuilder_file_imports

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" != "dashbuilder.runtime.import"* ]]
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.import.base.dir=/opt/kie/data/imports"* ]]
}

@test "test configure_dashbuilder_file_imports function with DASHBUILDER_MODEL_UPDATE env" {
    export DASHBUILDER_MODEL_UPDATE="false"

    configure_dashbuilder_file_imports

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" != "dashbuilder.runtime.import"* ]]
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.import.base.dir=/opt/kie/data/imports"* ]]
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.model.update=false"* ]]
}

@test "test configure_dashbuilder_file_imports function with DASHBUILDER_MODEL_FILE_REMOVAL default value" {
    configure_dashbuilder_file_imports

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" != "dashbuilder.runtime.import"* ]]
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.import.base.dir=/opt/kie/data/imports"* ]]
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.removeModelFile=false"* ]]
}

@test "test configure_dashbuilder_file_imports function with DASHBUILDER_MODEL_FILE_REMOVAL true value" {
    export DASHBUILDER_MODEL_FILE_REMOVAL="true"

    configure_dashbuilder_file_imports

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" != "dashbuilder.runtime.import"* ]]
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.import.base.dir=/opt/kie/data/imports"* ]]
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.removeModelFile=true"* ]]
}

@test "test configure_dashbuilder_file_imports function with DASHBUILDER_MODEL_FILE_REMOVAL nonsense value" {
    export DASHBUILDER_MODEL_FILE_REMOVAL="nonsense"

    configure_dashbuilder_file_imports

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" != "dashbuilder.runtime.import"* ]]
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.import.base.dir=/opt/kie/data/imports"* ]]
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.removeModelFile=false"* ]]
}

@test "test configure_dasbuilder_file_import_properties function with default value" {
    configure_dasbuilder_file_import_properties

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    [ "${JBOSS_KIE_DASHBUILDER_ARGS}" = " -Ddashbuilder.runtime.multi=false" ]
}

@test "test DASHBUILDER_RUNTIME_MULTIPLE_IMPORT env with custom value" {
    export DASHBUILDER_RUNTIME_MULTIPLE_IMPORT="true"

    configure_dasbuilder_file_import_properties

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    [ "${JBOSS_KIE_DASHBUILDER_ARGS}" = " -Ddashbuilder.runtime.multi=true" ]
}

@test "test DASHBUILDER_RUNTIME_MULTIPLE_IMPORT env  with invalid value" {
    export DASHBUILDER_RUNTIME_MULTIPLE_IMPORT="nonsense"

    configure_dasbuilder_file_import_properties

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    [ "${JBOSS_KIE_DASHBUILDER_ARGS}" = " -Ddashbuilder.runtime.multi=false" ]
}

@test "test DASHBUILDER_UPLOAD_SIZE env  with invalid value" {
    export DASHBUILDER_UPLOAD_SIZE="1000000"

    configure_dasbuilder_file_import_properties

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.runtime.multi=false"* ]]
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.runtime.upload.size=1000000"* ]]
}


@test "test configure_dashbuilder_external_component with default component dir" {
    export DASHBUILDER_COMP_ENABLE="true"

    configure_dashbuilder_external_component

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.components.enable=true"* ]]
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.components.dir=/opt/kie/data/components"* ]]
}

@test "test configure_dashbuilder_external_component with custom component dir" {
    export DASHBUILDER_COMP_ENABLE="true"
    export DASHBUILDER_EXTERNAL_COMP_DIR="/tmp"

    configure_dashbuilder_external_component

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.components.enable=true"* ]]
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.components.dir=/tmp"* ]]
}

@test "test configure_dashbuilder_external_component with nonsense component dir" {
    export DASHBUILDER_COMP_ENABLE="true"
    export DASHBUILDER_EXTERNAL_COMP_DIR="nonsense"

    configure_dashbuilder_external_component

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.components.enable=true"* ]]
    [[ "${JBOSS_KIE_DASHBUILDER_ARGS}" = *" -Ddashbuilder.components.dir=/opt/kie/data/components"* ]]
}

@test "test configuration with config_map" {
    export DASHBUILDER_CONFIG_MAP_PROPS="$BATS_TEST_DIRNAME/props/dashbuilder.properties"
    expected="-Ddashbuilder.runtime.allowExternal=true -Ddashbuilder.components.partition=true -Ddashbuilder.dataset.partition=true -Ddashbuilder.import.base.dir=/opt/kie/data/imports -Ddashbuilder.removeModelFile=false -Ddashbuilder.runtime.multi=true -Ddashbuilder.runtime.import=/tmp -Ddashbuilder.runtime.upload.size=1000"

    configure

    echo "Result: ${JBOSS_KIE_DASHBUILDER_ARGS}"
    echo "Expected: ${expected}"

    [ "${JBOSS_KIE_DASHBUILDER_ARGS}" = "${expected}" ]
}

@test "test Kie Server dataset with credentials" {
    export KIESERVER_DATASETS="dataset_test"
    export dataset_test_LOCATION="http://localmoon.com"
    export dataset_test_REPLACE_QUERY="true"
    export dataset_test_USER="moon"
    export dataset_test_PASSWORD="sun"

    expected=" -Ddashbuilder.kieserver.dataset.dataset_test.location=http://localmoon.com -Ddashbuilder.kieserver.dataset.dataset_test.replace_query=true -Ddashbuilder.kieserver.dataset.dataset_test.user=moon -Ddashbuilder.kieserver.dataset.dataset_test.password=sun"

    configure_dashbuilder_kieserver_dataset

    echo "Result  : ${JBOSS_KIE_DASHBUILDER_ARGS}"
    echo "Expected: ${expected}"
    [ "${JBOSS_KIE_DASHBUILDER_ARGS}" = "${expected}" ]
}

@test "test Kie Server dataset with token and no replace query" {
    export KIESERVER_DATASETS="DataSetTest"
    export DataSetTest_LOCATION="http://localmoon.com"

    export DataSetTest_TOKEN="cool_token"

    expected=" -Ddashbuilder.kieserver.dataset.DataSetTest.location=http://localmoon.com -Ddashbuilder.kieserver.dataset.DataSetTest.replace_query=false -Ddashbuilder.kieserver.dataset.DataSetTest.token=cool_token"

    configure_dashbuilder_kieserver_dataset

    echo "Result  : ${JBOSS_KIE_DASHBUILDER_ARGS}"
    echo "Expected: ${expected}"
    [ "${JBOSS_KIE_DASHBUILDER_ARGS}" = "${expected}" ]
}

@test "test multiple Kie Server dataset with no replace query with credentials and token with replace_query" {
    export KIESERVER_DATASETS="dataset_test,DataSetTest"
    export dataset_test_LOCATION="http://localmoon.com"
    export dataset_test_USER="moon"
    export dataset_test_PASSWORD="sun"
    export DataSetTest_LOCATION="http://localmoon.com"
     export DataSetTest_REPLACE_QUERY="true"
    export DataSetTest_TOKEN="cool_token"

    expected=" -Ddashbuilder.kieserver.dataset.dataset_test.location=http://localmoon.com -Ddashbuilder.kieserver.dataset.dataset_test.replace_query=false -Ddashbuilder.kieserver.dataset.dataset_test.user=moon -Ddashbuilder.kieserver.dataset.dataset_test.password=sun -Ddashbuilder.kieserver.dataset.DataSetTest.location=http://localmoon.com -Ddashbuilder.kieserver.dataset.DataSetTest.replace_query=true -Ddashbuilder.kieserver.dataset.DataSetTest.token=cool_token"

    configure_dashbuilder_kieserver_dataset

    echo "Result  : ${JBOSS_KIE_DASHBUILDER_ARGS}"
    echo "Expected: ${expected}"
    [ "${JBOSS_KIE_DASHBUILDER_ARGS}" = "${expected}" ]
}

@test "test multiple Kie Server dataset with credentials with env and properties file" {
    export DASHBUILDER_CONFIG_MAP_PROPS="$BATS_TEST_DIRNAME/props/dashbuilder-dataset.properties"
    export KIESERVER_DATASETS="dataset_test"
    export dataset_test_LOCATION="http://localmoon.com"
    export dataset_test_USER="moon"
    export dataset_test_PASSWORD="sun"

    expected="-Ddashbuilder.runtime.allowExternal=false -Ddashbuilder.components.partition=true -Ddashbuilder.dataset.partition=true -Ddashbuilder.import.base.dir=/opt/kie/data/imports -Ddashbuilder.removeModelFile=false -Ddashbuilder.runtime.multi=false -Ddashbuilder.kieserver.dataset.dataset_test.location=http://localmoon.com -Ddashbuilder.kieserver.dataset.dataset_test.replace_query=false -Ddashbuilder.kieserver.dataset.dataset_test.user=moon -Ddashbuilder.kieserver.dataset.dataset_test.password=sun -Ddashbuilder.kieserver.dataset.DataSetTest.location=http://localmoon.com -Ddashbuilder.kieserver.dataset.DataSetTest.user=test -Ddashbuilder.kieserver.dataset.DataSetTest.password=test_pwd"

    configure

    echo "Result  : ${JBOSS_KIE_DASHBUILDER_ARGS}"
    echo "Expected: ${expected}"
    [ "${JBOSS_KIE_DASHBUILDER_ARGS}" = "${expected}" ]
}

@test "test Kie Server server template with credentials" {
    export KIESERVER_SERVER_TEMPLATES="server_template_test"
    export server_template_test_LOCATION="http://localmoon.com"
    export server_template_test_USER="moon"
    export server_template_test_PASSWORD="sun"

    expected=" -Ddashbuilder.kieserver.serverTemplate.server_template_test.location=http://localmoon.com -Ddashbuilder.kieserver.serverTemplate.server_template_test.replace_query=false -Ddashbuilder.kieserver.serverTemplate.server_template_test.user=moon -Ddashbuilder.kieserver.serverTemplate.server_template_test.password=sun"

    configure_dashbuilder_kieserver_server_template

    echo "Result  : ${JBOSS_KIE_DASHBUILDER_ARGS}"
    echo "Expected: ${expected}"
    [ "${JBOSS_KIE_DASHBUILDER_ARGS}" = "${expected}" ]
}

@test "test Kie Server server template with token" {
    export KIESERVER_SERVER_TEMPLATES="ServerTemplateTest"
    export ServerTemplateTest_LOCATION="http://localmoon.com"
    export ServerTemplateTest_TOKEN="my_cool_token"

    expected=" -Ddashbuilder.kieserver.serverTemplate.ServerTemplateTest.location=http://localmoon.com -Ddashbuilder.kieserver.serverTemplate.ServerTemplateTest.replace_query=false -Ddashbuilder.kieserver.serverTemplate.ServerTemplateTest.token=my_cool_token"

    configure_dashbuilder_kieserver_server_template

    echo "Result  : ${JBOSS_KIE_DASHBUILDER_ARGS}"
    echo "Expected: ${expected}"
    [ "${JBOSS_KIE_DASHBUILDER_ARGS}" = "${expected}" ]
}

@test "test multiple Kie Server server template with credentials and token" {
    export KIESERVER_SERVER_TEMPLATES="server_template_test,ServerTemplateTest"
    export server_template_test_LOCATION="http://localmoon.com"
    export server_template_test_USER="moon"
    export server_template_test_PASSWORD="sun"
    export ServerTemplateTest_LOCATION="http://localmoon.com"
    export ServerTemplateTest_TOKEN="my_cool_token"

    expected=" -Ddashbuilder.kieserver.serverTemplate.server_template_test.location=http://localmoon.com -Ddashbuilder.kieserver.serverTemplate.server_template_test.replace_query=false -Ddashbuilder.kieserver.serverTemplate.server_template_test.user=moon -Ddashbuilder.kieserver.serverTemplate.server_template_test.password=sun -Ddashbuilder.kieserver.serverTemplate.ServerTemplateTest.location=http://localmoon.com -Ddashbuilder.kieserver.serverTemplate.ServerTemplateTest.replace_query=false -Ddashbuilder.kieserver.serverTemplate.ServerTemplateTest.token=my_cool_token"

    configure_dashbuilder_kieserver_server_template

    echo "Result  : ${JBOSS_KIE_DASHBUILDER_ARGS}"
    echo "Expected: ${expected}"
    [ "${JBOSS_KIE_DASHBUILDER_ARGS}" = "${expected}" ]
}

@test "test multiple Kie Server server template with credentials with env and properties file" {
    export DASHBUILDER_CONFIG_MAP_PROPS="$BATS_TEST_DIRNAME/props/dashbuilder-server-template.properties"
    export KIESERVER_SERVER_TEMPLATES="server_template_test"
    export server_template_test_LOCATION="http://localmoon.com"
    export server_template_test_USER="moon"
    export server_template_test_PASSWORD="sun"

    expected="-Ddashbuilder.runtime.allowExternal=false -Ddashbuilder.components.partition=true -Ddashbuilder.dataset.partition=true -Ddashbuilder.import.base.dir=/opt/kie/data/imports -Ddashbuilder.removeModelFile=false -Ddashbuilder.runtime.multi=false -Ddashbuilder.kieserver.serverTemplate.server_template_test.location=http://localmoon.com -Ddashbuilder.kieserver.serverTemplate.server_template_test.replace_query=false -Ddashbuilder.kieserver.serverTemplate.server_template_test.user=moon -Ddashbuilder.kieserver.serverTemplate.server_template_test.password=sun -Ddashbuilder.kieserver.serverTemplate.ServerTemplateTest.location=http://localmoon.com -Ddashbuilder.kieserver.serverTemplate.ServerTemplateTest.user=test -Ddashbuilder.kieserver.serverTemplate.ServerTemplateTest.password=test_pwd"

    configure

    echo "Result  : ${JBOSS_KIE_DASHBUILDER_ARGS}"
    echo "Expected: ${expected}"
    [ "${JBOSS_KIE_DASHBUILDER_ARGS}" = "${expected}" ]
}
