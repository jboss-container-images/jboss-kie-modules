#!/usr/bin/env bats

# bug in bats with set -eu?
export BATS_TEST_SKIPPED=

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
export CONFIG_FILE=$JBOSS_HOME/standalone/configuration/standalone-openshift.xml

mkdir -p $JBOSS_HOME/bin/launch
cp ../../../../test-common/logging.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../../added/launch/configure_logger_category.sh $JBOSS_HOME/bin/launch
source $JBOSS_HOME/bin/launch/configure_logger_category.sh

setup() {
  mkdir -p $JBOSS_HOME/standalone/configuration
  cp $BATS_TEST_DIRNAME/../../../../os-eap71-openshift/added/standalone-openshift.xml $JBOSS_HOME/standalone/configuration
}

teardown() {
  rm -rf $JBOSS_HOME
}


@test "Add 1 logger category" {
  #this is the return of xmllint --xpath "//*[local-name()='subsystem']//*[local-name()='logger']" $CONFIG_FILE | sed -e 's| ||g'
  expected=$(cat <<EOF
<loggercategory="com.arjuna">
<levelname="WARN"/>
</logger><loggercategory="org.jboss.as.config">
<levelname="DEBUG"/>
</logger><loggercategory="sun.rmi">
<levelname="WARN"/>
</logger><loggercategory="com.my.package">
<levelname="DEBUG"/>
</logger>
EOF
)
  LOGGER_CATEGORIES=com.my.package:DEBUG
  run add_logger_category
  result=$(xmllint --xpath "//*[local-name()='subsystem']//*[local-name()='logger']" $CONFIG_FILE | sed 's| ||g')
  echo "Expected: ${expected}"
  echo "Result: ${result}"
  [ "${result}" = "${expected}" ]
}

@test "Add 2 logger categories" {
  #this is the return of xmllint --xpath "//*[local-name()='subsystem']//*[local-name()='logger']" $CONFIG_FILE | sed -e 's| ||g'
  expected=$(cat <<EOF
<loggercategory="com.arjuna">
<levelname="WARN"/>
</logger><loggercategory="org.jboss.as.config">
<levelname="DEBUG"/>
</logger><loggercategory="sun.rmi">
<levelname="WARN"/>
</logger><loggercategory="com.my.package">
<levelname="DEBUG"/>
</logger><loggercategory="my.other.package">
<levelname="ERROR"/>
</logger>
EOF
)
  LOGGER_CATEGORIES=com.my.package:DEBUG,my.other.package:ERROR
  run add_logger_category
  result=$(xmllint --xpath "//*[local-name()='subsystem']//*[local-name()='logger']" $CONFIG_FILE | sed 's| ||g')
  echo "Expected: ${expected}"
  echo "Result: ${result}"
  [ "${result}" = "${expected}" ]
}

@test "Add 3 logger categories, one with no log level" {
  #this is the return of xmllint --xpath "//*[local-name()='subsystem']//*[local-name()='logger']" $CONFIG_FILE | sed -e 's| ||g'
  expected=$(cat <<EOF
<loggercategory="com.arjuna">
<levelname="WARN"/>
</logger><loggercategory="org.jboss.as.config">
<levelname="DEBUG"/>
</logger><loggercategory="sun.rmi">
<levelname="WARN"/>
</logger><loggercategory="com.my.package">
<levelname="DEBUG"/>
</logger><loggercategory="my.other.package">
<levelname="ERROR"/>
</logger><loggercategory="my.another.package">
<levelname="FINE"/>
</logger>
EOF
)
  LOGGER_CATEGORIES=com.my.package:DEBUG,my.other.package:ERROR,my.another.package
  run add_logger_category
  result=$(xmllint --xpath "//*[local-name()='subsystem']//*[local-name()='logger']" $CONFIG_FILE | sed 's| ||g')
  echo "Expected: ${expected}"
  echo "Result: ${result}"
  [ "${result}" = "${expected}" ]
}

@test "Add 3 logger categories with spaces" {
  #this is the return of xmllint --xpath "//*[local-name()='subsystem']//*[local-name()='logger']" $CONFIG_FILE | sed -e 's| ||g'
  expected=$(cat <<EOF
<loggercategory="com.arjuna">
<levelname="WARN"/>
</logger><loggercategory="org.jboss.as.config">
<levelname="DEBUG"/>
</logger><loggercategory="sun.rmi">
<levelname="WARN"/>
</logger><loggercategory="com.my.package">
<levelname="DEBUG"/>
</logger><loggercategory="my.other.package">
<levelname="ERROR"/>
</logger><loggercategory="my.another.package">
<levelname="FINE"/>
</logger>
EOF
)
  LOGGER_CATEGORIES=" com.my.package:DEBUG, my.other.package:ERROR, my.another.package"
  run add_logger_category
  result=$(xmllint --xpath "//*[local-name()='subsystem']//*[local-name()='logger']" $CONFIG_FILE | sed 's| ||g')
  echo "Expected: ${expected}"
  echo "Result: ${result}"
  [ "${result}" = "${expected}" ]
}

@test "Add 2 logger categories one with invalid log level" {
  #this is the return of xmllint --xpath "//*[local-name()='subsystem']//*[local-name()='logger']" $CONFIG_FILE | sed -e 's| ||g'
  expected=$(cat <<EOF
<loggercategory="com.arjuna">
<levelname="WARN"/>
</logger><loggercategory="org.jboss.as.config">
<levelname="DEBUG"/>
</logger><loggercategory="sun.rmi">
<levelname="WARN"/>
</logger><loggercategory="com.my.package">
<levelname="DEBUG"/>
</logger>
EOF
)
  LOGGER_CATEGORIES=com.my.package:DEBUG,my.other.package:UNKNOWN_LOG_LEVEL
  run add_logger_category
  result=$(xmllint --xpath "//*[local-name()='subsystem']//*[local-name()='logger']" $CONFIG_FILE | sed 's| ||g')
  echo "Expected: ${expected}"
  echo "Result: ${result}"
  [ "${result}" = "${expected}" ]
}