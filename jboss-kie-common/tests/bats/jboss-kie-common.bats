#!/usr/bin/env bats

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
mkdir -p $JBOSS_HOME/bin/launch

cp $BATS_TEST_DIRNAME/../../../tests/bats/common/launch-common.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../tests/bats/common/logging.bash $JBOSS_HOME/bin/launch/logging.sh

# imports
source $BATS_TEST_DIRNAME/../../added/launch/jboss-kie-common.sh

# mock function from jboss-kie-common.sh
unset -f query_route

function query_route() {
    echo "Querying route" >&2
    local response=$(cat $BATS_TEST_DIRNAME/mock_responses/single-route.json)
    response="${response}200"
    echo "${response}"
}

teardown() {
    rm -rf $JBOSS_HOME
}

@test "check if route protocol returns its default value" {
    local expected="http"
    local result=$(query_route_protocol)
    echo "Result is ${result} and expected is ${expected}" >&2
    [ "${expected}" = "${result}" ]
}

@test "check if route protocol returns passed protocol" {
    local expected="https"
    local result=$(query_route_protocol "my-route" ${expected})
    echo "Result is ${result} and expected is ${expected}" >&2
    [ "${expected}" = "${result}" ]
}

@test "check if route protocol queries the correct protocol" {
    local expected="https"
    # passing the wrong default protocol (mock will return https)
    local result=$(query_route_protocol "my-route" "http")
    echo "Result is ${result} and expected is ${expected}" >&2
    [ "${expected}" = "${result}" ]
}

@test "check if build_route_url creates a default url" {
    local expected="https://myapp-my-namespace.com:443"
    local result=$(build_route_url "my-route" "https" "${HOSTNAME}")
    echo "Result is ${result} and expected is ${expected}" >&2
    [ "${expected}" = "${result}" ]
}

@test "check if build_route_url does not create a secure url with port 80" {
    local expected="https://myapp-my-namespace.com:443/"
    local result=$(build_route_url "my-route" "https" "${HOSTNAME}" "80" "/")
    echo "Result is ${result} and expected is ${expected}" >&2
    [ "${expected}" = "${result}" ]
}

@test "check if build_route_url obey non standard secure port" {
    local expected="https://myapp-my-namespace.com:8443/"
    local result=$(build_route_url "my-route" "https" "${HOSTNAME}" "8443" "/")
    echo "Result is ${result} and expected is ${expected}" >&2
    [ "${expected}" = "${result}" ]
}