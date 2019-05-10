#!/bin/sh
# Link DB drivers, provided by RPM packages, into the "openshift" layer
set -e

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added

function link {
  mkdir -p $(dirname $2)
  ln -s $1 $2
}

link /usr/lib/java/mariadb-java-client.jar $JBOSS_HOME/modules/system/layers/openshift/org/mariadb/main/mariadb-java-client.jar
link /usr/share/java/postgresql-jdbc.jar $JBOSS_HOME/modules/system/layers/openshift/org/postgresql/main/postgresql-jdbc.jar

# module definitions for MariaDB, PostgreSQL
# Remove any existing destination files first (which might be symlinks)
cp -rp --remove-destination "$ADDED_DIR/modules" "$JBOSS_HOME/"

CONFIG_FILE=${JBOSS_HOME}/standalone/configuration/standalone-openshift.xml
drivers="\
<driver name=\"mariadb\" module=\"org.mariadb\">\
    <xa-datasource-class>org.mariadb.jdbc.MariaDbDataSource</xa-datasource-class>\
</driver>\
<driver name=\"postgresql\" module=\"org.postgresql\">\
    <xa-datasource-class>org.postgresql.xa.PGXADataSource</xa-datasource-class>\
</driver>\
"
sed -i "s|<!-- ##DRIVERS## -->|${drivers}<!-- ##DRIVERS## -->|" $CONFIG_FILE
