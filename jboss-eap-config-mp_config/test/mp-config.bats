
# dont enable these by default, bats on CI doesn't output anything if they are set
#set -euo pipefail
#IFS=$'\n\t'

# bug in bats with set -eu?
export BATS_TEST_SKIPPED=

# fake JBOSS_HOME
export JBOSS_HOME=$BATS_TEST_DIRNAME
# fake the logger so we don't have to deal with colors
export BATS_LOGGING_INCLUDE=$BATS_TEST_DIRNAME/../../test-common/logging.sh

load $BATS_TEST_DIRNAME/../added/launch/mp-config.sh

setup() {
  export CONFIG_FILE=${BATS_TMPDIR}/standalone-openshift.xml
}

teardown() {
  if [ -n "${CONFIG_FILE}" ] && [ -f "${CONFIG_FILE}" ]; then
    rm "${CONFIG_FILE}"
  fi
}

@test "Unconfigured" {
  run generate_microprofile_config_source
  [ "${output}" = "" ]
  [ "$status" -eq 0 ]
}

@test "Configure MICROPROFILE_CONFIG_DIR_ORDINAL=150 -- ordinal only" {
  run generate_microprofile_config_source "" "150"
  [ "${output}" = "" ]
  [ "$status" -eq 0 ]
}

@test "Configure MICROPROFILE_CONFIG_DIR=$BATS_TEST_DIRNAME" {

  run generate_microprofile_config_source "${BATS_TEST_DIRNAME}"
  echo ${output}
  [ "$status" -eq 0 ]

  result=$(check_dir_config "${BATS_TEST_DIRNAME}" "500" "${output}")
  [ -n "${result}" ]
}

@test "Configure MICROPROFILE_CONFIG_DIR=$BATS_TEST_DIRNAME MICROPROFILE_CONFIG_DIR_ORDINAL=150" {

  run generate_microprofile_config_source "${BATS_TEST_DIRNAME}" "150"
  echo ${output}
  [ "$status" -eq 0 ]

  result=$(check_dir_config "${BATS_TEST_DIRNAME}" "150" "${output}")
  [ -n "${result}" ]
}

@test "Configure MICROPROFILE_CONFIG_DIR=etc/config" {

  run generate_microprofile_config_source "etc/config"
  echo ${output}
  [ "$status" -eq 0 ]

  echo "${lines[0]}" | grep -q "WARN MICROPROFILE_CONFIG_DIR value 'etc/config' is not an absolute path"
  [ $? -eq 0 ]

  result=$(check_dir_config "etc/config" "500" "${lines[1]}")
  [ -n "${result}" ]
}

@test "Configure MICROPROFILE_CONFIG_DIR=jboss.home MICROPROFILE_CONFIG_DIR_ORDINAL=150" {

  run generate_microprofile_config_source "jboss.home" "150"
  echo ${output}
  [ "$status" -eq 0 ]

  echo "${lines[0]}" | grep -q "WARN MICROPROFILE_CONFIG_DIR value 'jboss.home' is not an absolute path"
  [ $? -eq 0 ]

  result=$(check_dir_config "jboss.home" "150" "${lines[1]}")
  [ -n "${result}" ]
}

@test "Configure MICROPROFILE_CONFIG_DIR=/bogus/beyond/belief" {

  run generate_microprofile_config_source "/bogus/beyond/belief"
  echo ${output}
  [ "$status" -eq 0 ]

  echo "${lines[0]}" | grep -q "WARN MICROPROFILE_CONFIG_DIR value '/bogus/beyond/belief' is a non-existent path"
  [ $? -eq 0 ]

  result=$(check_dir_config "/bogus/beyond/belief" "500" "${lines[1]}")
  [ -n "${result}" ]
}

@test "Configure MICROPROFILE_CONFIG_DIR=/bogus/beyond/belief MICROPROFILE_CONFIG_DIR_ORDINAL=150" {

  run generate_microprofile_config_source "/bogus/beyond/belief" "150"
  echo ${output}
  [ "$status" -eq 0 ]

  echo "${lines[0]}" | grep -q "WARN MICROPROFILE_CONFIG_DIR value '/bogus/beyond/belief' is a non-existent path"
  [ $? -eq 0 ]

  result=$(check_dir_config "/bogus/beyond/belief" "150" "${lines[1]}")
  [ -n "${result}" ]
}

@test "Configure MICROPROFILE_CONFIG_DIR=$BATS_LOGGING_INCLUDE" {

  run generate_microprofile_config_source "${BATS_LOGGING_INCLUDE}"
  echo ${output}
  [ "$status" -eq 0 ]

  echo "${lines[0]}" | grep "WARN MICROPROFILE_CONFIG_DIR value '${BATS_LOGGING_INCLUDE}' is not a directory"
  [ $? -eq 0 ]

  result=$(check_dir_config "${BATS_LOGGING_INCLUDE}" "500" "${lines[1]}")
  [ -n "${result}" ]
}

@test "Configure MICROPROFILE_CONFIG_DIR=BATS_LOGGING_INCLUDE MICROPROFILE_CONFIG_DIR_ORDINAL=150" {

  run generate_microprofile_config_source "${BATS_LOGGING_INCLUDE}" "150"
  echo ${output}
  [ "$status" -eq 0 ]
  echo "${lines[0]}" | grep -q "WARN MICROPROFILE_CONFIG_DIR value '${BATS_LOGGING_INCLUDE}' is not a directory"
  [ $? -eq 0 ]

  result=$(check_dir_config "${BATS_LOGGING_INCLUDE}" "150" "${lines[1]}")
  [ -n "${result}" ]
}

check_dir_config() {
  declare dir_name=$1 ordinal=$2 toCheck=$3
  expected=$(cat <<EOF
<?xml version="1.0"?>
   <config-source ordinal="$ordinal" name="config-map"><dir path="$dir_name"/></config-source>
EOF
)
  result=$(echo ${toCheck} | sed 's|\\n||g' | xmllint --format --noblanks -)
  expected=$(echo "${expected}" | sed 's|\\n||g' | xmllint --format --noblanks -)
  if [ "${result}" = "${expected}" ]; then
    echo $result
  fi
}

